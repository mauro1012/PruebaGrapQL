# BLOQUE 1: CONFIGURACIÓN INICIAL Y BACKEND
provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket  = "examen-suple-grpc-2026"
    key     = "microservicios-graphql/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# BLOQUE 2: DATA SOURCES (RED POR DEFECTO)
data "aws_vpc" "default" { 
  default = true 
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# BLOQUE 3: SEGURIDAD (SECURITY GROUPS)

# Seguridad para el punto de entrada de las mutaciones GraphQL
resource "aws_security_group" "sg_graphql_alb" {
  name        = "sg_graphql_external_access"
  description = "Permite trafico HTTP para el Gateway de GraphQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Seguridad para los nodos internos que procesan GraphQL
resource "aws_security_group" "sg_graphql_nodes" {
  name        = "sg_graphql_internal_nodes"
  description = "Permite comunicacion interna para el cluster GraphQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_graphql_alb.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# BLOQUE 4: BALANCEADOR DE CARGA (ALB)
resource "aws_lb" "graphql_alb" {
  name               = "alb-microservicios-graphql"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_graphql_alb.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "graphql_tg" {
  name     = "tg-gateway-graphql-3000"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "graphql_listener" {
  load_balancer_arn = aws_lb.graphql_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphql_tg.arn
  }
}

# BLOQUE 5: AUTO SCALING Y DOCKER ORCHESTRATION
resource "aws_launch_template" "graphql_lt" {
  name_prefix   = "lt-node-graphql-"
  image_id      = "ami-0c7217cdde317cfec" 
  instance_type = "t2.micro"
  key_name      = var.ssh_key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_graphql_nodes.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y docker.io docker-compose
              sudo systemctl start docker

              mkdir -p /home/ubuntu/app && cd /home/ubuntu/app

              cat <<EOT > docker-compose.yml
              version: '3.8'
              services:
                db-redis-cache:
                  image: redis:latest
                  restart: always

                svc-auditoria-backend:
                  image: ${var.docker_user}/servicio-auditoria:latest
                  environment:
                    - PORT=4000
                    - REDIS_HOST=db-redis-cache
                    - BUCKET_NAME=${var.bucket_logs}
                    - AWS_ACCESS_KEY_ID=${var.aws_access_key}
                    - AWS_SECRET_ACCESS_KEY=${var.aws_secret_key}
                    - AWS_SESSION_TOKEN=${var.aws_session_token}
                  depends_on:
                    - db-redis-cache
                  restart: always

                gateway-graphql-entrypoint:
                  image: ${var.docker_user}/gateway-graphql:latest
                  ports:
                    - "3000:3000"
                  environment:
                    - PORT=3000
                    - AUDITORIA_URL=http://svc-auditoria-backend:4000/registrar
                  depends_on:
                    - svc-auditoria-backend
                  restart: always
              EOT
              sudo docker-compose up -d
              EOF
  )
}

resource "aws_autoscaling_group" "graphql_asg" {
  name                = "asg-cluster-graphql-notif"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.graphql_tg.arn]
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.graphql_lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "EC2-GraphQL-Gateway" 
    propagate_at_launch = true
  }
}

# BLOQUE 6: ALMACENAMIENTO DE AUDITORIA
resource "aws_s3_bucket" "graphql_auditoria_logs" {
  bucket        = var.bucket_logs
  force_destroy = true
}

# BLOQUE 7: SALIDAS
output "endpoint_publico_graphql" {
  description = "DNS del Balanceador para conectar el Sender"
  value       = aws_lb.graphql_alb.dns_name
}