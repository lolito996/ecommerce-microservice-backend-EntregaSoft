# 🚀 Guía Completa de Despliegue y Uso de la Infraestructura AWS

## 📁 Estructura del Proyecto

```
infra/
├── modules/                           # ✅ Módulos reutilizables de Terraform
│   ├── aws-vpc/                      # VPC, subnets, NAT Gateway, Internet Gateway
│   ├── aws-ecs/                      # ECS Fargate cluster y configuraciones
│   ├── aws-ecs-services/             # Definiciones de servicios ECS individuales
│   ├── aws-alb/                      # Application Load Balancer y Target Groups
│   ├── aws-security-groups/          # Security Groups para ALB, ECS, RDS
│   ├── aws-rds/                      # PostgreSQL database Multi-AZ
│   └── aws-s3-backend/               # Backend remoto S3 + DynamoDB
│
├── aws-backend-bootstrap/             # ✅ Inicialización del backend de Terraform
│   ├── main.tf                       # Configuración de S3 y DynamoDB
│   ├── variables.tf                  # Variables del backend
│   ├── outputs.tf                    # Outputs (bucket name, table name)
│   └── backend-config.txt            # Config generada automáticamente
│
├── aws-environments/                  # ✅ Configuración por ambiente
│   ├── dev/                          # Development (10.0.0.0/16)
│   │   ├── main.tf                   # Configuración principal DEV
│   │   ├── variables.tf              # Variables específicas de DEV
│   │   ├── outputs.tf                # Outputs (ALB DNS, cluster ARN, etc)
│   │   └── deployment-info.json      # Info del último despliegue
│   ├── stage/                        # Staging (10.1.0.0/16)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── alb-routing.tf            # Routing personalizado para staging
│   └── prod/                         # Production (10.2.0.0/16)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── scripts/                           # ✅ Scripts de automatización y despliegue
│   ├── init-backend.ps1              # Inicializa backend S3 + DynamoDB
│   ├── deploy-environment.ps1        # Despliega ambiente completo (Terraform)
│   ├── validate-terraform.ps1        # Valida configuración Terraform
│   ├── deploy-all-services.ps1       # Despliega todos los microservicios
│   ├── deploy-to-ecs.ps1             # Despliega servicios individuales
│   ├── register-and-deploy-services.ps1  # Registra task definitions y despliega
│   ├── deploy-monitoring-ecs.ps1     # Despliega Prometheus y Grafana
│   ├── deploy-monitoring-to-ecs.ps1  # Deploy monitoring con configuración
│   ├── expose-monitoring-via-alb.ps1 # Configura ALB para Grafana/Prometheus
│   ├── configure-grafana.ps1         # Configura dashboards en Grafana
│   ├── configure-prometheus.ps1      # Configura scraping en Prometheus
│   ├── check-services-health.ps1     # Verifica salud de servicios
│   ├── migrate-to-ghcr.ps1           # Migra imágenes a GitHub Container Registry
│   ├── update-ecs-to-ghcr.ps1        # Actualiza task definitions a GHCR
│   ├── update-workflow-to-ghcr.ps1   # Actualiza CI/CD para usar GHCR
│   ├── update-eureka-config.ps1      # Actualiza configuración de Eureka
│   ├── create-prod-services.ps1      # Crea servicios en producción
│   ├── create-services-staging.ps1   # Crea servicios en staging
│   ├── register-taskdefs-staging.ps1 # Registra task definitions para staging
│   ├── push-images-staging.ps1       # Sube imágenes para staging
│   └── MONITORING_URLS.md            # URLs de monitoreo por ambiente
│
├── README.md                          # ✅ Guía de referencia rápida
├── AWS_INFRASTRUCTURE_GUIDE.md        # ✅ Documentación completa de AWS
├── AWS_ARCHITECTURE.md                # ✅ Arquitectura detallada de AWS
├── TERRAFORM_STRUCTURE.md             # ✅ Estructura y organización de Terraform
├── ARCHITECTURE_DIAGRAMS.md           # ✅ Diagramas arquitectónicos (Mermaid)
└── QUICK_START.md                     # ✅ Esta guía
```

## 🎯 Despliegue Completo - Paso a Paso

### 📋 Prerequisitos

Antes de comenzar, asegúrate de tener instalado:

1. **AWS CLI** (v2 o superior)
   ```powershell
   # Verificar instalación
   aws --version
   
   # Instalar si es necesario
   winget install Amazon.AWSCLI
   ```

2. **Terraform** (v1.5.0 o superior)
   ```powershell
   # Verificar instalación
   terraform version
   
   # Instalar si es necesario
   winget install Hashicorp.Terraform
   ```

3. **PowerShell** (v7 o superior)
   ```powershell
   # Verificar versión
   $PSVersionTable.PSVersion
   ```

4. **Credenciales de AWS** con permisos suficientes:
   - VPC, Subnets, Internet Gateway, NAT Gateway
   - ECS, Fargate, Task Definitions
   - RDS (PostgreSQL)
   - Application Load Balancer, Target Groups
   - S3, DynamoDB
   - IAM Roles y Policies
   - CloudWatch Logs

---

## 🚀 PARTE 1: Configuración Inicial (Primera Vez)

### 1️⃣ Configurar AWS CLI

```powershell
# Configurar credenciales de AWS
aws configure

# Ingresar cuando se solicite:
# AWS Access Key ID: AKIA****************
# AWS Secret Access Key: ****************************
# Default region name: us-east-1
# Default output format: json

# Verificar configuración
aws sts get-caller-identity
```

**Output esperado:**
```json
{
    "UserId": "AIDA****************",
    "Account": "533924338325",
    "Arn": "arn:aws:iam::533924338325:user/your-user"
}
```

---

### 2️⃣ Clonar el Repositorio

```powershell
# Clonar el proyecto
git clone https://github.com/gerson05/ecommerce-microservice-backend-EntregaSoft.git
cd ecommerce-microservice-backend-EntregaSoft/infra
```

---

### 3️⃣ Inicializar Backend de Terraform (Una sola vez)

Este paso crea el bucket S3 y la tabla DynamoDB para almacenar el estado de Terraform de forma remota y segura.

```powershell
# Ir al directorio de scripts
cd scripts

# Ejecutar script de inicialización
.\init-backend.ps1
```

**¿Qué hace este script?**
1. Navega a `aws-backend-bootstrap/`
2. Ejecuta `terraform init`
3. Crea el plan con `terraform plan`
4. Aplica los cambios con `terraform apply`
5. Crea recursos:
   - 🪣 S3 Bucket: `ecommerce-terraform-state-{account-id}`
   - 🔒 DynamoDB Table: `terraform-state-lock`
6. Genera archivo `backend-config.txt` con la configuración

**Output esperado:**
```
✅ Backend S3 bucket creado: ecommerce-terraform-state-533924338325
✅ DynamoDB table creada: terraform-state-lock
✅ Archivo backend-config.txt generado
```

---

### 4️⃣ Configurar Backend en Cada Ambiente

Después de crear el backend, debes configurar cada ambiente para usarlo.

**Opción A: Configuración Manual**

Edita los archivos `main.tf` de cada ambiente y descomentar/actualizar la sección backend:

```powershell
# Editar dev/main.tf
code ../aws-environments/dev/main.tf

# Editar stage/main.tf  
code ../aws-environments/stage/main.tf

# Editar prod/main.tf
code ../aws-environments/prod/main.tf
```

**Descomentar y actualizar:**
```terraform
terraform {
  backend "s3" {
    bucket         = "ecommerce-terraform-state-533924338325"  # ← Usar tu bucket
    key            = "dev/terraform.tfstate"                   # ← Cambiar según ambiente
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

**Opción B: Usar Backend Config File**

Usar el archivo `backend-config.txt` generado:

```powershell
# Inicializar con backend config
cd ../aws-environments/dev
terraform init -backend-config=../../aws-backend-bootstrap/backend-config.txt
```

---

## 🏗️ PARTE 2: Despliegue de Infraestructura Base

### 5️⃣ Validar Configuración de Terraform

Antes de desplegar, valida que todo esté correctamente configurado:

```powershell
cd scripts
.\validate-terraform.ps1
```

**¿Qué hace este script?**
1. Verifica sintaxis de Terraform en todos los módulos
2. Ejecuta `terraform fmt` para formatear código
3. Ejecuta `terraform validate` en cada ambiente
4. Reporta errores si los encuentra

**Output esperado:**
```
✅ Validando módulo aws-vpc... OK
✅ Validando módulo aws-ecs... OK
✅ Validando módulo aws-alb... OK
✅ Validando ambiente dev... OK
✅ Validando ambiente stage... OK
✅ Validando ambiente prod... OK
✅ Todas las validaciones pasaron exitosamente
```

---

### 6️⃣ Desplegar Ambiente de Desarrollo

```powershell
# Desplegar ambiente DEV completo
.\deploy-environment.ps1 -Environment dev
```

**¿Qué hace este script?**
1. Navega a `aws-environments/dev/`
2. Ejecuta `terraform init` (si no se ha hecho)
3. Ejecuta `terraform plan -out=dev.tfplan`
4. Muestra los recursos que se crearán
5. Solicita confirmación
6. Ejecuta `terraform apply dev.tfplan`
7. Crea toda la infraestructura:
   - ✅ VPC (10.0.0.0/16)
   - ✅ Subnets públicas y privadas (2 AZs)
   - ✅ Internet Gateway
   - ✅ NAT Gateways (2)
   - ✅ Security Groups (ALB, ECS, RDS)
   - ✅ Application Load Balancer
   - ✅ Target Groups (12 servicios)
   - ✅ ECS Cluster (dev-ecommerce-cluster)
   - ✅ RDS PostgreSQL (opcional)
   - ✅ IAM Roles (Task Execution, Task Role)
   - ✅ CloudWatch Log Groups
8. Guarda outputs en `deployment-info.json`

**Tiempo estimado:** 10-15 minutos

**Output esperado:**
```
Apply complete! Resources: 45 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name = "dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com"
cluster_name = "dev-ecommerce-cluster"
cluster_arn = "arn:aws:ecs:us-east-1:533924338325:cluster/dev-ecommerce-cluster"
vpc_id = "vpc-0abc123def456"
private_subnet_ids = ["subnet-0123", "subnet-0456"]
public_subnet_ids = ["subnet-0789", "subnet-0abc"]
```

**Otros ambientes:**

```powershell
# Staging
.\deploy-environment.ps1 -Environment stage

# Production
.\deploy-environment.ps1 -Environment prod
```

---

### 7️⃣ Verificar Infraestructura Creada

```powershell
# Ver outputs del ambiente
cd ../aws-environments/dev
terraform output

# Ver DNS del ALB
terraform output alb_dns_name

# Ver lista completa de recursos
terraform state list

# Ver detalles de un recurso específico
terraform state show aws_ecs_cluster.main
```

**Verificar en AWS Console:**
1. **VPC**: https://console.aws.amazon.com/vpc/
2. **ECS**: https://console.aws.amazon.com/ecs/
3. **Load Balancers**: https://console.aws.amazon.com/ec2/v2/home#LoadBalancers
4. **RDS**: https://console.aws.amazon.com/rds/

---

## 🐳 PARTE 3: Despliegue de Microservicios

### 8️⃣ Registrar Task Definitions

Antes de desplegar servicios, necesitas registrar las definiciones de tareas en ECS:

```powershell
cd ../../scripts

# Registrar todas las task definitions para DEV
.\register-and-deploy-services.ps1 -Environment dev -Action register
```

**¿Qué hace este script?**
1. Lee las definiciones de tareas de cada microservicio
2. Registra en ECS las task definitions:
   - `dev-cloud-config`
   - `dev-service-discovery`
   - `dev-api-gateway`
   - `dev-user-service`
   - `dev-product-service`
   - `dev-order-service`
   - `dev-payment-service`
   - `dev-shipping-service`
   - `dev-favourite-service`
   - `dev-proxy-client`
3. Configura:
   - CPU: 512 (0.5 vCPU)
   - Memory: 1024 MB (1 GB)
   - Network mode: awsvpc
   - Launch type: FARGATE
   - Environment variables
   - Health checks
   - Log configuration

**Output esperado:**
```
✅ Task definition registrada: dev-cloud-config:1
✅ Task definition registrada: dev-service-discovery:1
✅ Task definition registrada: dev-api-gateway:1
...
✅ 10 task definitions registradas exitosamente
```

---

### 9️⃣ Desplegar Todos los Servicios

```powershell
# Desplegar todos los microservicios en DEV
.\deploy-all-services.ps1 -Environment dev
```

**¿Qué hace este script?**
1. Verifica que el cluster ECS existe
2. Verifica que las task definitions están registradas
3. Crea servicios ECS para cada microservicio:
   - Desired count: 1
   - Launch type: FARGATE
   - Network: Private subnets
   - Security group: ECS tasks SG
   - Load balancer: Conecta con target groups
4. Configura health check grace period: 60 segundos
5. Habilita circuit breaker para rollback automático
6. Espera a que los servicios estén RUNNING

**Orden de despliegue:**
1. ☁️ Cloud Config (puerto 9296)
2. 🔍 Service Discovery / Eureka (puerto 8761)
3. 🌐 API Gateway (puerto 8080)
4. 👤 User Service (puerto 8081)
5. 📦 Product Service (puerto 8082)
6. 🛒 Order Service (puerto 8083)
7. 💳 Payment Service (puerto 8084)
8. 🚚 Shipping Service (puerto 8085)
9. ⭐ Favourite Service (puerto 8086)
10. 🔌 Proxy Client (puerto 8087)

**Tiempo estimado:** 5-10 minutos

**Output esperado:**
```
📦 Desplegando servicio: dev-cloud-config
✅ Servicio dev-cloud-config creado exitosamente
📦 Desplegando servicio: dev-service-discovery
✅ Servicio dev-service-discovery creado exitosamente
...
✅ 10 servicios desplegados exitosamente
🎉 Todos los servicios están en estado RUNNING
```

---

### 🔟 Desplegar Servicio Individual

Si necesitas desplegar o actualizar un servicio específico:

```powershell
# Desplegar un servicio específico
.\deploy-to-ecs.ps1 -ServiceName user-service -Environment dev

# Parámetros disponibles:
# -ServiceName: api-gateway, user-service, product-service, etc.
# -Environment: dev, stage, prod
# -TaskDefinition: (opcional) versión específica de task definition
# -DesiredCount: (opcional) número de tareas, default 1
```

**Ejemplo con opciones:**
```powershell
# Desplegar user-service con 2 instancias
.\deploy-to-ecs.ps1 -ServiceName user-service -Environment dev -DesiredCount 2

# Desplegar versión específica de task definition
.\deploy-to-ecs.ps1 -ServiceName api-gateway -Environment dev -TaskDefinition dev-api-gateway:3
```

---

## 📊 PARTE 4: Despliegue de Monitoreo

### 1️⃣1️⃣ Desplegar Prometheus y Grafana

```powershell
# Desplegar stack completo de monitoreo
.\deploy-monitoring-ecs.ps1 -Environment dev
```

**¿Qué hace este script?**
1. Construye imágenes Docker para Prometheus y Grafana
2. Sube imágenes a GitHub Container Registry (GHCR)
3. Registra task definitions:
   - `dev-prometheus` (puerto 9090)
   - `dev-grafana` (puerto 3000)
4. Crea servicios ECS
5. Conecta con target groups del ALB
6. Configura health checks

**Output esperado:**
```
🔨 Construyendo imagen de Prometheus...
✅ Imagen construida: ghcr.io/lolito996/prometheus-dev:subpath-v3
📤 Subiendo imagen a GHCR...
✅ Imagen subida exitosamente

🔨 Construyendo imagen de Grafana...
✅ Imagen construida: grafana/grafana:latest
✅ Task definitions registradas
✅ Servicios creados exitosamente
```

---

### 1️⃣2️⃣ Exponer Monitoreo vía ALB

```powershell
# Configurar ALB para acceder a Grafana y Prometheus
.\expose-monitoring-via-alb.ps1 -Environment dev
```

**¿Qué hace este script?**
1. Crea listener rules en el ALB:
   - `/grafana/*` → dev-grafana-tg (prioridad 90)
   - `/prometheus/*` → dev-prometheus-tg (prioridad 91)
2. Configura health checks:
   - Grafana: `/api/health`
   - Prometheus: `/prometheus/-/ready`
3. Registra IPs de los contenedores en target groups
4. Espera a que los health checks pasen

**URLs de acceso:**
```
Grafana: http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com/grafana
Prometheus: http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com/prometheus

Credenciales Grafana:
Usuario: admin
Password: admin123
```

---

### 1️⃣3️⃣ Configurar Dashboards de Grafana

```powershell
# Importar dashboards predefinidos a Grafana
.\configure-grafana.ps1 -Environment dev
```

**¿Qué hace este script?**
1. Se conecta a Grafana via API
2. Configura datasource de Prometheus
3. Importa dashboards:
   - All Services Overview
   - Complete Microservices Monitoring
   - Microservices E-Commerce Dashboard
4. Configura alertas (opcional)

**Dashboards importados:**
- 📊 **All Services Overview**: Vista general de todos los servicios
- 📈 **Complete Microservices Monitoring**: Métricas detalladas
- 🎯 **Microservices E-Commerce**: Específico para e-commerce

---

### 1️⃣4️⃣ Configurar Scraping de Prometheus

```powershell
# Actualizar configuración de Prometheus para scraping
.\configure-prometheus.ps1 -Environment dev
```

**¿Qué hace este script?**
1. Obtiene IPs actuales de todos los servicios
2. Actualiza `prometheus-dev.yml` con las IPs
3. Reconstruye imagen de Prometheus
4. Actualiza task definition
5. Fuerza redespliegue del servicio

**Servicios monitoreados:**
```yaml
- dev-api-gateway (10.0.10.185:8080/actuator/prometheus)
- dev-cloud-config (10.0.20.66:9296/actuator/prometheus)
- dev-service-discovery (10.0.10.96:8761/actuator/prometheus)
- dev-proxy-client (10.0.20.124:8087/actuator/prometheus)
- dev-favourite-service (pending)
- dev-user-service (pending)
- dev-product-service (pending)
- ... otros servicios
```

---

## 🔍 PARTE 5: Verificación y Monitoreo

### 1️⃣5️⃣ Verificar Salud de Servicios

```powershell
# Verificar estado de todos los servicios
.\check-services-health.ps1 -Environment dev
```

**¿Qué hace este script?**
1. Lista todos los servicios en el cluster
2. Verifica el estado de cada servicio (RUNNING/STOPPED)
3. Verifica el desired count vs running count
4. Verifica health checks del ALB
5. Verifica target groups
6. Genera reporte de salud

**Output esperado:**
```
🔍 Verificando servicios en dev-ecommerce-cluster...

Servicio: dev-api-gateway
  Estado: RUNNING
  Tareas: 1/1
  Target Group: HEALTHY
  ✅ Servicio saludable

Servicio: dev-user-service
  Estado: RUNNING
  Tareas: 0/1
  Target Group: UNHEALTHY (Rate limit Docker Hub)
  ⚠️ Servicio con problemas

...

📊 Resumen:
  Total servicios: 12
  Servicios saludables: 6
  Servicios con problemas: 6
  Servicios detenidos: 0
```

---

### 1️⃣6️⃣ Ver Logs de Servicios

```powershell
# Ver logs en tiempo real de un servicio
aws logs tail /ecs/dev-api-gateway --follow --region us-east-1

# Ver últimas 50 líneas
aws logs tail /ecs/dev-api-gateway --since 5m --region us-east-1 | Select-Object -Last 50

# Ver logs de múltiples servicios
aws logs tail /ecs/dev-user-service --follow --region us-east-1
```

---

### 1️⃣7️⃣ Acceder a las Aplicaciones

**URLs principales:**

```
Application Load Balancer:
http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com

API Gateway:
http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com/api-gateway

Eureka Dashboard:
http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com/eureka

Grafana:
http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com/grafana
(admin / admin123)

Prometheus:
http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com/prometheus
```

---

## 🔄 PARTE 6: Actualización y Mantenimiento

## 📊 Recursos Creados por Ambiente

### Development (~$50-100/mes)
- VPC con 2 AZs
- ECS Fargate (SPOT instances)
- ALB público
- RDS opcional (deshabilitado por defecto)
- Sin NAT Gateway (ahorro de costos)

### Staging (~$200-300/mes)
- VPC con 2 AZs
- ECS Fargate (mix FARGATE/SPOT)
- ALB público
- RDS PostgreSQL Single-AZ (db.t3.small)
- NAT Gateways habilitados
- VPC Flow Logs (14 días)

### Production (~$500-800/mes)
- VPC con 3 AZs
- ECS Fargate (solo FARGATE para estabilidad)
- ALB público con HTTPS
- RDS PostgreSQL Multi-AZ (db.t3.medium)
- NAT Gateways en cada AZ
- VPC Flow Logs (30 días)
- CloudWatch Alarms
- Deletion protection habilitado

## 🏗️ Arquitectura AWS

```
Internet
   ↓
Application Load Balancer (ALB)
   ↓
ECS Fargate Cluster
   ├── API Gateway :8080
   ├── Service Discovery (Eureka) :8761
   ├── Cloud Config :9296
   ├── User Service :8700
   ├── Product Service :8500
   ├── Order Service :8300
   ├── Payment Service :8400
   ├── Shipping Service :8600
   ├── Favourite Service :8800
   ├── Proxy Client :8900
   ├── Prometheus :9090
   ├── Grafana :3000
   └── Zipkin :9411
   ↓
RDS PostgreSQL (Multi-AZ en Prod)
```

## 🔐 Características de Seguridad

✅ **Network Isolation**: VPC privada por ambiente  
✅ **Security Groups**: Reglas restrictivas  
✅ **Encrypted Storage**: RDS y S3 con encriptación  
✅ **Secrets Manager**: Credenciales seguras  
✅ **IAM Roles**: Sin credenciales hardcoded  
✅ **VPC Flow Logs**: Auditoría de tráfico  
✅ **Multi-AZ**: Alta disponibilidad en producción

## 📚 Documentación

- **[README.md](./README.md)** - Guía rápida
- **[AWS_INFRASTRUCTURE_GUIDE.md](./AWS_INFRASTRUCTURE_GUIDE.md)** - Documentación completa
- **[ARCHITECTURE_DIAGRAMS.md](./ARCHITECTURE_DIAGRAMS.md)** - Diagramas detallados

## 🔧 Comandos Útiles

```powershell
# Validar configuración
.\scripts\validate-terraform.ps1

# Ver plan sin aplicar
.\scripts\deploy-environment.ps1 -Environment dev -Plan

# Destruir ambiente (CUIDADO!)
.\scripts\deploy-environment.ps1 -Environment dev -Destroy

# Ver outputs
cd infra/aws-environments/dev
terraform output

# Ver estado
terraform show
```

## 🆘 Troubleshooting

**Error: Backend not configured**
```powershell
.\scripts\init-backend.ps1
# Luego actualizar backend config en main.tf
```

**Error: AWS credentials**
```powershell
aws configure
```

**Ver logs de ECS**
```powershell
aws logs tail /ecs/dev-ecommerce --follow
```

## ✅ Cumplimiento de Requisitos

- ✅ **Infraestructura como Código**: 100% Terraform
- ✅ **Estructura Modular**: 6 módulos reutilizables
- ✅ **Múltiples Ambientes**: dev, stage, prod configurados
- ✅ **Backend Remoto**: S3 + DynamoDB con state locking
- ✅ **Documentación**: 3 documentos completos + diagramas
- ✅ **Scripts de Automatización**: 3 scripts PowerShell

