variable "aws_region" {
  description = "Region de AWS para el despliegue"
  default     = "us-east-1"
}

variable "ssh_key_name" {
  description = "Nombre de tu llave .pem creada en AWS Academy"
}

variable "docker_user" {
  description = "Tu nombre de usuario de Docker Hub"
}

variable "bucket_logs" {
  description = "Bucket para persistencia de logs de auditoria"
  default     = "auditoria-granql-mauro28102023"
}

# Estas variables se llenan automaticamente desde los Secrets de GitHub
variable "aws_access_key" {
  description = "AWS Access Key ID"
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key"
}

variable "aws_session_token" {
  description = "AWS Session Token"
}