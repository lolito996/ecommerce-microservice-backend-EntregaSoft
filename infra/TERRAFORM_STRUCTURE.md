# Estructura de Terraform - E-commerce Microservices

## 📁 Organización del Proyecto

```
infra/
├── aws-backend-bootstrap/      # Bootstrap del backend remoto de Terraform
├── aws-environments/           # Configuraciones por ambiente
│   ├── dev/                   # Ambiente de desarrollo
│   ├── stage/                 # Ambiente de staging
│   └── prod/                  # Ambiente de producción
├── modules/                   # Módulos reutilizables de Terraform
│   ├── aws-alb/              # Application Load Balancer
│   ├── aws-ecs/              # ECS Cluster
│   ├── aws-ecs-services/     # ECS Services
│   ├── aws-rds/              # RDS Databases
│   ├── aws-s3-backend/       # S3 Backend
│   ├── aws-security-groups/  # Security Groups
│   └── aws-vpc/              # Virtual Private Cloud
└── scripts/                  # Scripts de despliegue y automatización
```

---

## 🏗️ Componentes Principales

### 1. **Backend Bootstrap** (`aws-backend-bootstrap/`)

Configura el estado remoto de Terraform usando S3 y DynamoDB.

**Archivos:**
- `main.tf` - Configuración del bucket S3 y tabla DynamoDB
- `variables.tf` - Variables de entrada
- `outputs.tf` - Outputs del backend creado
- `backend-config.txt` - Configuración generada para otros ambientes

**Recursos creados:**
- S3 Bucket: `ecommerce-terraform-state-{account-id}`
- DynamoDB Table: `terraform-state-lock`
- Versionamiento y encriptación habilitados

**Uso:**
```bash
cd aws-backend-bootstrap
terraform init
terraform apply
```

---

### 2. **Ambientes** (`aws-environments/`)

#### **DEV** (`dev/`)
Ambiente de desarrollo con recursos de menor capacidad.

**Configuración:**
- VPC: 10.0.0.0/16
- Subnets públicas: 2 (us-east-1a, us-east-1b)
- Subnets privadas: 2 (us-east-1a, us-east-1b)
- ECS Cluster: `dev-ecommerce-cluster`
- ALB: `dev-ecommerce-alb`
- RDS: PostgreSQL (db.t3.micro)
- Servicios ECS: 12 servicios (Fargate, 512 CPU / 1024 MB)

**Variables principales:**
```hcl
environment = "dev"
vpc_cidr = "10.0.0.0/16"
ecs_task_cpu = "512"
ecs_task_memory = "1024"
rds_instance_class = "db.t3.micro"
```

**Archivos:**
- `main.tf` - Configuración principal del ambiente
- `variables.tf` - Variables específicas de DEV
- `outputs.tf` - Outputs (ALB DNS, cluster ARN, etc.)
- `deployment-info.json` - Información de despliegue

#### **STAGE** (`stage/`)
Ambiente de staging para pruebas pre-producción.

**Configuración:**
- VPC: 10.1.0.0/16
- Similar a DEV pero con configuraciones de prueba
- ALB routing personalizado (`alb-routing.tf`)

#### **PROD** (`prod/`)
Ambiente de producción con alta disponibilidad.

**Configuración:**
- VPC: 10.2.0.0/16
- ECS con mayor capacidad (1024 CPU / 2048 MB)
- RDS con Multi-AZ habilitado
- Auto-scaling configurado

---

## 🧩 Módulos Reutilizables

### **Module: aws-vpc** (`modules/aws-vpc/`)

Crea la infraestructura de red base.

**Recursos creados:**
- VPC con CIDR personalizado
- Internet Gateway
- NAT Gateway (uno por AZ)
- Subnets públicas y privadas
- Route tables
- VPC Flow Logs

**Variables de entrada:**
```hcl
variable "environment" {}
variable "vpc_cidr" {}
variable "public_subnet_cidrs" {}
variable "private_subnet_cidrs" {}
variable "availability_zones" {}
```

**Outputs:**
- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`
- `nat_gateway_ids`

---

### **Module: aws-security-groups** (`modules/aws-security-groups/`)

Define grupos de seguridad para diferentes componentes.

**Security Groups creados:**

1. **ALB Security Group**
   - Ingress: 80, 443 (0.0.0.0/0)
   - Egress: All traffic

2. **ECS Tasks Security Group**
   - Ingress: Todos los puertos TCP desde ALB SG
   - Ingress: 8080-9296 (interno VPC)
   - Egress: All traffic

3. **RDS Security Group**
   - Ingress: 5432 desde ECS Tasks SG
   - Egress: None

**Variables:**
```hcl
variable "vpc_id" {}
variable "environment" {}
variable "vpc_cidr" {}
```

---

### **Module: aws-alb** (`modules/aws-alb/`)

Configura el Application Load Balancer.

**Recursos creados:**
- Application Load Balancer
- Target Groups (uno por servicio)
- Listener HTTP (puerto 80)
- Listener Rules para routing por path

**Target Groups creados:**
```
- dev-api-gateway-tg      (/api-gateway/*)
- dev-user-service-tg     (/user-service/*)
- dev-product-service-tg  (/product-service/*)
- dev-order-service-tg    (/order-service/*)
- dev-payment-service-tg  (/payment-service/*)
- dev-shipping-service-tg (/shipping-service/*)
- dev-favourite-service-tg (/favourite-service/*)
- dev-grafana-tg          (/grafana/*)
- dev-prometheus-tg       (/prometheus/*)
```

**Health Check configurado:**
- Path: `/actuator/health` (microservicios)
- Interval: 30 segundos
- Timeout: 5 segundos
- Healthy threshold: 2
- Unhealthy threshold: 3

**Variables:**
```hcl
variable "environment" {}
variable "vpc_id" {}
variable "public_subnet_ids" {}
variable "alb_security_group_id" {}
```

---

### **Module: aws-ecs** (`modules/aws-ecs/`)

Crea el cluster ECS y configuraciones base.

**Recursos:**
- ECS Cluster con capacidad Fargate
- CloudWatch Log Groups
- IAM Roles:
  - `ecsTaskExecutionRole` (pull de imágenes, logs)
  - `ecsTaskRole` (permisos de la aplicación)

**Configuración:**
- Container Insights habilitado
- Log retention: 7 días
- Fargate Spot habilitado (opcional)

---

### **Module: aws-ecs-services** (`modules/aws-ecs-services/`)

Define los servicios ECS (microservicios).

**Servicios creados:**

1. **Cloud Config** (Puerto 9296)
2. **Service Discovery (Eureka)** (Puerto 8761)
3. **API Gateway** (Puerto 8080)
4. **User Service** (Puerto 8081)
5. **Product Service** (Puerto 8082)
6. **Order Service** (Puerto 8083)
7. **Payment Service** (Puerto 8084)
8. **Shipping Service** (Puerto 8085)
9. **Favourite Service** (Puerto 8086)
10. **Proxy Client** (Puerto 8087)
11. **Prometheus** (Puerto 9090)
12. **Grafana** (Puerto 3000)

**Configuración por servicio:**
```hcl
resource "aws_ecs_service" "service" {
  name            = "${var.environment}-${var.service_name}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.service_name
    container_port   = var.container_port
  }
}
```

**Task Definition:**
- Network Mode: awsvpc
- Requires Compatibilities: FARGATE
- CPU: 512 (DEV), 1024 (PROD)
- Memory: 1024 MB (DEV), 2048 MB (PROD)
- Health checks configurados
- Environment variables inyectadas

---

### **Module: aws-rds** (`modules/aws-rds/`)

Configura bases de datos PostgreSQL.

**Recursos:**
- RDS Subnet Group
- RDS Parameter Group
- RDS Instance

**Configuración DEV:**
```hcl
engine                = "postgres"
engine_version        = "14.7"
instance_class        = "db.t3.micro"
allocated_storage     = 20
storage_encrypted     = true
multi_az              = false
backup_retention      = 7
```

**Configuración PROD:**
```hcl
instance_class        = "db.t3.medium"
allocated_storage     = 100
multi_az              = true
backup_retention      = 30
```

**Bases de datos:**
- `ecommerce_users`
- `ecommerce_products`
- `ecommerce_orders`
- `ecommerce_payments`

---

## 🔄 Flujo de Trabajo

### **1. Inicialización del Backend**
```bash
cd aws-backend-bootstrap
terraform init
terraform apply
```

### **2. Despliegue de Ambiente DEV**
```bash
cd aws-environments/dev
terraform init -backend-config=../../aws-backend-bootstrap/backend-config.txt
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
```

### **3. Despliegue de Servicios**
```bash
cd ../../scripts
./deploy-all-services.ps1 -Environment dev
```

### **4. Actualización de Configuración**
```bash
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
```

### **5. Destrucción de Ambiente**
```bash
terraform destroy -auto-approve
```

---

## 📊 State Management

### **Backend Configuration**

**S3 Backend:**
```hcl
terraform {
  backend "s3" {
    bucket         = "ecommerce-terraform-state-533924338325"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

**Características:**
- ✅ Estado remoto en S3
- ✅ Locking con DynamoDB
- ✅ Encriptación habilitada
- ✅ Versionamiento habilitado
- ✅ Backup automático

---

## 🔐 Variables Sensibles

Las variables sensibles se gestionan mediante:

1. **Variables de entorno:**
   ```bash
   export TF_VAR_db_password="secure_password"
   export TF_VAR_github_token="ghp_xxx"
   ```

2. **Terraform Cloud/Enterprise:**
   - Variables encriptadas
   - Workspace variables

3. **AWS Secrets Manager:**
   - Secretos recuperados en runtime
   - Rotación automática

---

## 📈 Outputs Importantes

### **DEV Environment Outputs:**
```hcl
output "alb_dns_name" {
  value = "dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com"
}

output "grafana_url" {
  value = "http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com/grafana"
}

output "prometheus_url" {
  value = "http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com/prometheus"
}

output "api_gateway_url" {
  value = "http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com/api-gateway"
}

output "ecs_cluster_name" {
  value = "dev-ecommerce-cluster"
}
```

---

## 🛠️ Scripts de Automatización

### **Deploy Scripts** (`scripts/`)

1. **`deploy-environment.ps1`**
   - Despliega ambiente completo (VPC, ECS, RDS, ALB)
   - Parámetros: -Environment, -AutoApprove

2. **`deploy-all-services.ps1`**
   - Registra task definitions
   - Crea servicios ECS
   - Configura target groups

3. **`deploy-monitoring-ecs.ps1`**
   - Despliega Prometheus y Grafana
   - Configura scraping de métricas
   - Expone via ALB

4. **`migrate-to-ghcr.ps1`**
   - Migra imágenes de Docker Hub a GHCR
   - Actualiza task definitions
   - Redespliega servicios

5. **`check-services-health.ps1`**
   - Verifica estado de servicios
   - Chequea health checks
   - Genera reporte

---

## 🎯 Best Practices Implementadas

### **1. Modularización**
- ✅ Módulos reutilizables
- ✅ Separación por responsabilidad
- ✅ Versionamiento de módulos

### **2. Multi-Ambiente**
- ✅ Variables por ambiente
- ✅ Configuraciones específicas
- ✅ Isolation entre ambientes

### **3. Seguridad**
- ✅ Security Groups restrictivos
- ✅ Subnets privadas para ECS
- ✅ RDS sin acceso público
- ✅ Secrets Manager para credenciales
- ✅ IAM roles con mínimos privilegios

### **4. Alta Disponibilidad**
- ✅ Multi-AZ deployment
- ✅ ALB con health checks
- ✅ Auto-scaling (PROD)
- ✅ RDS Multi-AZ (PROD)

### **5. Observabilidad**
- ✅ CloudWatch Logs
- ✅ Container Insights
- ✅ Prometheus metrics
- ✅ Grafana dashboards

### **6. Infraestructura como Código**
- ✅ Todo definido en Terraform
- ✅ State remoto y locking
- ✅ CI/CD integration
- ✅ Validación automática

---

## 📝 Comandos Útiles

### **Terraform**
```bash
# Formatear código
terraform fmt -recursive

# Validar configuración
terraform validate

# Ver plan
terraform plan

# Aplicar cambios
terraform apply

# Ver estado
terraform show

# Listar recursos
terraform state list

# Importar recurso existente
terraform import aws_ecs_cluster.main dev-ecommerce-cluster
```

### **AWS CLI**
```bash
# Ver servicios ECS
aws ecs list-services --cluster dev-ecommerce-cluster

# Ver tareas corriendo
aws ecs list-tasks --cluster dev-ecommerce-cluster --service-name dev-api-gateway

# Ver logs
aws logs tail /ecs/dev-api-gateway --follow

# Ver target groups
aws elbv2 describe-target-groups --names dev-api-gateway-tg
```

---

## 🔄 Versionamiento

**Terraform Version:** >= 1.5.0
**Provider AWS:** ~> 5.0
**Provider Random:** ~> 3.5

---

## 📚 Referencias

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
