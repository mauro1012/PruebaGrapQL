
#  Sistema de Microservicios con RabbitMQ y AWS

Este proyecto implementa una arquitectura de microservicios distribuida, utilizando **RabbitMQ** como broker de mensajería, **Redis** para caché y **AWS S3** para almacenamiento, todo orquestado mediante un API Gateway con **Apollo Server (GraphQL)**.

##  Estructura del Proyecto

El sistema se divide en tres componentes principales:

### 1. Auditoría (`auditoria`)
Encargado de procesar logs y persistir datos en AWS S3 y Redis.
* **Instalación:**
    ```bash
    npm init -y
    npm install express @aws-sdk/client-s3 redis dotenv
    ```

### 2. API Gateway (`gateway`)
Punto de entrada único que utiliza GraphQL para la comunicación.
* **Instalación:**
    ```bash
    npm init -y
    npm install apollo-server-express express graphql axios cors dotenv
    ```

### 3. Sender (`sender`)
Servicio encargado de la emisión de mensajes y comunicación externa.
* **Instalación:**
    ```bash
    npm init -y 
    npm install axios
    ```

---

##  Comprobación de Estado (Health Check)

Para verificar que el balanceador de carga (ALB) y los servicios están respondiendo correctamente, puedes acceder a la siguiente ruta:

```http
http://<dns-de-tu-alb>/health

```

---

##  Repositorios siguitne 
https://github.com/mauro1012/PreubaRest.git
 