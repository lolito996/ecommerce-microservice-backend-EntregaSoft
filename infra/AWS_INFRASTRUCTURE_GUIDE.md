# Arquitectura de Infraestructura AWS - E-Commerce Microservices

## 📋 Tabla de Contenidos
- [Resumen Ejecutivo](#resumen-ejecutivo)
- [Arquitectura General](#arquitectura-general)
- [Ambientes](#ambientes)
- [Componentes de Infraestructura](#componentes-de-infraestructura)
- [Módulos de Terraform](#módulos-de-terraform)
- [Backend Remoto](#backend-remoto)
- [Seguridad](#seguridad)
- [Costos Estimados](#costos-estimados)
- [Instrucciones de Despliegue](#instrucciones-de-despliegue)

---

## 🎯 Resumen Ejecutivo

Esta arquitectura implementa una solución de microservicios en AWS utilizando servicios administrados para garantizar alta disponibilidad, escalabilidad y seguridad. La infraestructura está completamente definida como código usando Terraform con una estructura modular reutilizable.

### Características Principales
- ✅ **Multi-ambiente**: Dev, Stage, Prod con configuraciones diferenciadas
- ✅ **Alta Disponibilidad**: Multi-AZ en producción
- ✅ **Escalabilidad**: ECS Fargate con auto-scaling
- ✅ **Seguridad**: Encriptación, VPC aislada, Secrets Manager
- ✅ **Observabilidad**: CloudWatch, Prometheus, Grafana
- ✅ **IaC**: 100% Infrastructure as Code con Terraform
- ✅ **State Management**: Backend remoto en S3 con locking en DynamoDB

---

## 🏗️ Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                  INTERNET                                    │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │  Application Load      │
                    │     Balancer (ALB)     │
                    │   Public Subnets       │
                    └────────┬───────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   AZ-1a      │    │   AZ-1b      │    │   AZ-1c      │
│              │    │              │    │  (Prod only) │
└──────────────┘    └──────────────┘    └──────────────┘

PUBLIC SUBNET LAYER (10.x.1.0/24, 10.x.2.0/24, 10.x.3.0/24)
├── ALB (Application Load Balancer)
├── NAT Gateways
└── Internet Gateway

PRIVATE SUBNET LAYER (10.x.10.0/24, 10.x.20.0/24, 10.x.30.0/24)
├── ECS Fargate Tasks
│   ├── API Gateway (8080)
│   ├── Service Discovery/Eureka (8761)
│   ├── Cloud Config (9296)
│   ├── User Service (8700)
│   ├── Product Service (8500)
│   ├── Order Service (8300)
│   ├── Payment Service (8400)
│   ├── Shipping Service (8600)
│   ├── Favourite Service (8800)
│   ├── Proxy Client (8900)
│   ├── Prometheus (9090)
│   ├── Grafana (3000)
│   └── Zipkin (9411)
│
└── RDS PostgreSQL (Multi-AZ in Prod)
    └── Automated Backups
    └── Encrypted Storage
```

### Diagrama de Red por Ambiente

#### Development (10.0.0.0/16)
```
┌─────────────────────────────────────────────────────────┐
│ VPC: 10.0.0.0/16                                       │
│                                                         │
│  Public Subnets (2 AZs)                                │
│  ├── 10.0.1.0/24 (us-east-1a) - ALB                   │
│  └── 10.0.2.0/24 (us-east-1b) - ALB                   │
│                                                         │
│  Private Subnets (2 AZs)                               │
│  ├── 10.0.10.0/24 (us-east-1a) - ECS Tasks            │
│  └── 10.0.20.0/24 (us-east-1b) - ECS Tasks            │
│                                                         │
│  NAT Gateway: Disabled (cost saving)                   │
│  RDS: Optional (can use local DBs)                     │
└─────────────────────────────────────────────────────────┘
```

#### Staging (10.1.0.0/16)
```
┌─────────────────────────────────────────────────────────┐
│ VPC: 10.1.0.0/16                                       │
│                                                         │
│  Public Subnets (2 AZs)                                │
│  ├── 10.1.1.0/24 (us-east-1a) - ALB, NAT GW           │
│  └── 10.1.2.0/24 (us-east-1b) - ALB, NAT GW           │
│                                                         │
│  Private Subnets (2 AZs)                               │
│  ├── 10.1.10.0/24 (us-east-1a) - ECS, RDS             │
│  └── 10.1.20.0/24 (us-east-1b) - ECS, RDS             │
│                                                         │
│  NAT Gateway: Enabled                                  │
│  RDS: Single-AZ (db.t3.small)                          │
└─────────────────────────────────────────────────────────┘
```

#### Production (10.2.0.0/16)
```
┌─────────────────────────────────────────────────────────┐
│ VPC: 10.2.0.0/16                                       │
│                                                         │
│  Public Subnets (3 AZs)                                │
│  ├── 10.2.1.0/24 (us-east-1a) - ALB, NAT GW           │
│  ├── 10.2.2.0/24 (us-east-1b) - ALB, NAT GW           │
│  └── 10.2.3.0/24 (us-east-1c) - ALB, NAT GW           │
│                                                         │
│  Private Subnets (3 AZs)                               │
│  ├── 10.2.10.0/24 (us-east-1a) - ECS, RDS Primary     │
│  ├── 10.2.20.0/24 (us-east-1b) - ECS, RDS Standby     │
│  └── 10.2.30.0/24 (us-east-1c) - ECS                  │
│                                                         │
│  NAT Gateway: Enabled (per AZ)                         │
│  RDS: Multi-AZ (db.t3.medium)                          │
│  Features: Flow Logs, CloudWatch Alarms, HTTPS         │
└─────────────────────────────────────────────────────────┘
```

---

## 🌍 Ambientes

### Comparación de Ambientes

| Característica | Development | Staging | Production |
|----------------|-------------|---------|------------|
| **VPC CIDR** | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| **Availability Zones** | 2 | 2 | 3 |
| **NAT Gateway** | ❌ Deshabilitado | ✅ Habilitado | ✅ Habilitado |
| **RDS** | Opcional | Single-AZ | Multi-AZ |
| **RDS Instance** | db.t3.micro | db.t3.small | db.t3.medium |
| **ECS Capacity** | FARGATE_SPOT | FARGATE/SPOT | FARGATE |
| **HTTPS** | ❌ | Opcional | ✅ |
| **VPC Flow Logs** | ❌ | ✅ (14 días) | ✅ (30 días) |
| **CloudWatch Logs** | 7 días | 14 días | 30 días |
| **Deletion Protection** | ❌ | ❌ | ✅ |
| **Backups** | 3 días | 7 días | 30 días |
| **Costo Mensual** | ~$50-100 | ~$200-300 | ~$500-800 |

---

## 🔧 Componentes de Infraestructura

### 1. Networking (VPC)
- **VPC aislada** por ambiente
- **Subnets públicas**: Para ALB y NAT Gateways
- **Subnets privadas**: Para ECS tasks y RDS
- **Internet Gateway**: Conectividad externa
- **NAT Gateways**: Salida de tráfico desde subnets privadas
- **Route Tables**: Enrutamiento configurado por tipo de subnet

### 2. Compute (ECS Fargate)
- **ECS Cluster** con Container Insights
- **Fargate**: Serverless, sin gestión de EC2
- **Task Definitions** para cada microservicio:
  - API Gateway
  - Service Discovery (Eureka)
  - Cloud Config Server
  - Business Microservices (User, Product, Order, Payment, Shipping, Favourite)
  - Proxy Client
  - Monitoring (Prometheus, Grafana)
  - Tracing (Zipkin)

### 3. Load Balancing (ALB)
- **Application Load Balancer** público
- **Target Groups** para cada servicio
- **Health Checks** configurados
- **Path-based routing**: `/api/*` → API Gateway
- **HTTPS** con certificados ACM (Prod/Stage)

### 4. Database (RDS PostgreSQL)
- **PostgreSQL 15.4**
- **Automated Backups**: 3-30 días según ambiente
- **Multi-AZ**: Solo en producción
- **Encrypted Storage**: AES-256
- **Parameter Groups**: Configuración optimizada
- **Secrets Manager**: Almacenamiento seguro de credenciales

### 5. Security
- **Security Groups**:
  - ALB: Puertos 80, 443
  - ECS Tasks: Comunicación interna + desde ALB
  - RDS: Puerto 5432 solo desde ECS
- **IAM Roles**:
  - ECS Task Execution Role
  - ECS Task Role (para acceso a AWS services)
- **Secrets Manager**: Passwords de DB
- **VPC Flow Logs**: Auditoría de tráfico

### 6. Monitoring & Logging
- **CloudWatch Logs**: Logs de ECS tasks
- **CloudWatch Alarms**: CPU, memoria, response time
- **Prometheus**: Métricas de aplicación
- **Grafana**: Dashboards y visualización
- **Zipkin**: Distributed tracing

---

## 📦 Módulos de Terraform

La infraestructura está organizada en módulos reutilizables:

```
infra/
├── modules/
│   ├── aws-vpc/              # Networking completo
│   ├── aws-ecs/              # ECS cluster y roles IAM
│   ├── aws-alb/              # Load balancer y target groups
│   ├── aws-security-groups/  # Security groups
│   ├── aws-rds/              # Base de datos PostgreSQL
│   └── aws-s3-backend/       # Backend para Terraform state
├── aws-backend-bootstrap/    # Inicialización del backend
└── aws-environments/
    ├── dev/                  # Configuración desarrollo
    ├── stage/                # Configuración staging
    └── prod/                 # Configuración producción
```

### Módulo: aws-vpc
**Propósito**: Crear toda la infraestructura de red

**Recursos creados**:
- VPC con DNS habilitado
- Subnets públicas y privadas en múltiples AZs
- Internet Gateway
- NAT Gateways (opcional)
- Route Tables
- VPC Flow Logs (opcional)

**Variables principales**:
- `vpc_cidr`: CIDR del VPC
- `public_subnet_cidrs`: Lista de CIDRs para subnets públicas
- `private_subnet_cidrs`: Lista de CIDRs para subnets privadas
- `availability_zones`: Lista de AZs
- `enable_nat_gateway`: Habilitar NAT Gateways

### Módulo: aws-ecs
**Propósito**: Configurar ECS cluster y roles IAM

**Recursos creados**:
- ECS Cluster con Container Insights
- IAM Role para Task Execution
- IAM Role para Tasks
- CloudWatch Log Group

**Variables principales**:
- `enable_container_insights`: CloudWatch Container Insights
- `capacity_providers`: FARGATE, FARGATE_SPOT
- `log_retention_days`: Retención de logs

### Módulo: aws-alb
**Propósito**: Load balancer y distribución de tráfico

**Recursos creados**:
- Application Load Balancer
- Listeners HTTP/HTTPS
- Target Groups para cada servicio
- Listener Rules con path-based routing

**Variables principales**:
- `enable_https`: Habilitar HTTPS
- `certificate_arn`: ARN del certificado ACM
- `internal`: ALB interno o externo

### Módulo: aws-rds
**Propósito**: Base de datos relacional

**Recursos creados**:
- RDS PostgreSQL instance
- DB Subnet Group
- Parameter Group
- Secrets Manager para password
- Automated backups

**Variables principales**:
- `instance_class`: Tipo de instancia
- `multi_az`: Habilitar Multi-AZ
- `backup_retention_period`: Días de retención de backups
- `deletion_protection`: Protección contra borrado

### Módulo: aws-s3-backend
**Propósito**: Backend remoto para Terraform state

**Recursos creados**:
- S3 Bucket con versionado y encriptación
- DynamoDB Table para state locking
- IAM Policy para acceso al backend

---

## 🔐 Backend Remoto

### Arquitectura del Backend

```
┌─────────────────────────────────────────────────────────────┐
│                    Terraform Backend                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  S3 Bucket: ecommerce-terraform-state-XXXXXXXX             │
│  ├── dev/terraform.tfstate                                  │
│  ├── stage/terraform.tfstate                                │
│  └── prod/terraform.tfstate                                 │
│                                                              │
│  Features:                                                   │
│  ✓ Versioning enabled                                       │
│  ✓ Server-side encryption (AES256)                          │
│  ✓ Public access blocked                                    │
│  ✓ Lifecycle: 90 días para versiones antiguas              │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  DynamoDB Table: ecommerce-terraform-locks                  │
│  ├── Hash Key: LockID                                       │
│  ├── Billing: Pay per request                               │
│  └── Purpose: State locking & consistency                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Beneficios del Backend Remoto

1. **Colaboración en Equipo**: Estado compartido entre desarrolladores
2. **State Locking**: Previene modificaciones concurrentes
3. **Versionado**: Historial completo de cambios
4. **Seguridad**: Encriptación en reposo y tránsito
5. **Disaster Recovery**: Backups automáticos del state

---

## 🔒 Seguridad

### Capas de Seguridad

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Network Security                                   │
├─────────────────────────────────────────────────────────────┤
│ ✓ VPC Isolation                                             │
│ ✓ Public/Private Subnet Separation                          │
│ ✓ Security Groups (least privilege)                         │
│ ✓ Network ACLs                                              │
│ ✓ VPC Flow Logs (audit)                                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Application Security                               │
├─────────────────────────────────────────────────────────────┤
│ ✓ ALB with SSL/TLS termination                              │
│ ✓ Path-based routing                                        │
│ ✓ Health checks                                             │
│ ✓ DDoS protection (AWS Shield)                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Data Security                                      │
├─────────────────────────────────────────────────────────────┤
│ ✓ RDS encryption at rest (AES-256)                          │
│ ✓ Secrets Manager for credentials                           │
│ ✓ S3 bucket encryption                                      │
│ ✓ Automated backups                                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Layer 4: Identity & Access                                  │
├─────────────────────────────────────────────────────────────┤
│ ✓ IAM Roles (no hard-coded credentials)                     │
│ ✓ Least privilege policies                                  │
│ ✓ Service-specific roles                                    │
│ ✓ CloudTrail audit logs                                     │
└─────────────────────────────────────────────────────────────┘
```

### Security Groups Matrix

| Source | Target | Port | Protocol | Purpose |
|--------|--------|------|----------|---------|
| Internet | ALB | 80 | TCP | HTTP |
| Internet | ALB | 443 | TCP | HTTPS |
| ALB | ECS Tasks | All | TCP | Microservices |
| ECS Tasks | ECS Tasks | All | TCP | Inter-service communication |
| ECS Tasks | RDS | 5432 | TCP | Database access |
| ECS Tasks | Internet | All | TCP | External APIs, ECR pulls |

---

## 💰 Costos Estimados

### Costos Mensuales por Ambiente (us-east-1)

#### Development (~$50-100/mes)
```
Service              Cost/Month    Notes
─────────────────────────────────────────────────────
VPC                  $0            Free tier
ALB                  $16.20        ~$0.0225/hour
ECS Fargate          $30-50        2 vCPU, 4GB RAM (spot)
RDS (optional)       $0-20         db.t3.micro (if enabled)
NAT Gateway          $0            Disabled
Data Transfer        $5-10         Egress
CloudWatch           $3-5          Logs
─────────────────────────────────────────────────────
TOTAL                ~$54-101
```

#### Staging (~$200-300/mes)
```
Service              Cost/Month    Notes
─────────────────────────────────────────────────────
VPC                  $0            Free tier
ALB                  $16.20        ~$0.0225/hour
NAT Gateway          $64.80        2 gateways @ $32.40
ECS Fargate          $80-120       4 vCPU, 8GB RAM
RDS                  $37           db.t3.small, Single-AZ
Storage (RDS)        $11.50        50GB @ $0.23/GB
Backups              $2-5          Automated backups
Data Transfer        $15-25        Egress
CloudWatch           $10-15        Logs + Metrics
VPC Flow Logs        $3-5          14 days retention
─────────────────────────────────────────────────────
TOTAL                ~$240-298
```

#### Production (~$500-800/mes)
```
Service              Cost/Month    Notes
─────────────────────────────────────────────────────
VPC                  $0            Free tier
ALB                  $16.20        ~$0.0225/hour
NAT Gateway          $97.20        3 gateways @ $32.40
ECS Fargate          $200-350      8-12 vCPU, 16-24GB RAM
RDS                  $109          db.t3.medium, Multi-AZ
Storage (RDS)        $23           100GB @ $0.23/GB
Backups              $10-20        30 days + snapshots
Data Transfer        $30-60        Higher traffic
CloudWatch           $30-50        Extensive monitoring
VPC Flow Logs        $8-12         30 days retention
CloudWatch Alarms    $1-2          Multiple alarms
Secrets Manager      $0.80         2 secrets @ $0.40/month
─────────────────────────────────────────────────────
TOTAL                ~$525-739
```

### Optimización de Costos

**Para Development**:
- ✅ Usar FARGATE_SPOT (ahorro 70%)
- ✅ Deshabilitar NAT Gateways
- ✅ RDS opcional (usar local)
- ✅ Apagar recursos fuera de horas laborales

**Para Staging**:
- ✅ Single-AZ RDS
- ✅ Mix FARGATE/FARGATE_SPOT
- ✅ Retención de logs reducida

**Para Production**:
- ⚠️ No comprometer en seguridad/disponibilidad
- ✅ Reserved Capacity para RDS (30-40% ahorro)
- ✅ Optimizar imágenes Docker
- ✅ Usar Savings Plans para Fargate

---

## 🚀 Instrucciones de Despliegue

### Prerrequisitos

```bash
# 1. Instalar Terraform
# Windows (PowerShell):
choco install terraform

# Verificar instalación
terraform version  # >= 1.5.0

# 2. Configurar AWS CLI
aws configure
# AWS Access Key ID: [tu-access-key]
# AWS Secret Access Key: [tu-secret-key]
# Default region: us-east-1
# Default output format: json

# 3. Verificar credenciales
aws sts get-caller-identity
```

### Paso 1: Inicializar Backend Remoto

```bash
# Navegar al directorio de bootstrap
cd infra/aws-backend-bootstrap

# Inicializar Terraform
terraform init

# Revisar plan
terraform plan

# Aplicar (crear S3 bucket y DynamoDB table)
terraform apply

# IMPORTANTE: Anotar los outputs:
# - S3 Bucket Name
# - DynamoDB Table Name
```

### Paso 2: Configurar Backend en Ambientes

Después de crear el backend, actualizar `backend.tf` en cada ambiente:

```bash
# Editar infra/aws-environments/dev/main.tf
# Descomentar y actualizar la sección backend "s3" con:
#   bucket = "ecommerce-terraform-state-XXXXXXXX"
#   key    = "dev/terraform.tfstate"
#   region = "us-east-1"
#   dynamodb_table = "ecommerce-terraform-locks"
#   encrypt = true

# Repetir para stage y prod con sus respectivas keys
```

### Paso 3: Desplegar Development

```bash
cd infra/aws-environments/dev

# Inicializar
terraform init

# Validar configuración
terraform validate

# Revisar plan
terraform plan -out=dev.tfplan

# Aplicar
terraform apply dev.tfplan

# Ver outputs
terraform output
```

### Paso 4: Desplegar Staging

```bash
cd infra/aws-environments/stage

terraform init
terraform plan -out=stage.tfplan
terraform apply stage.tfplan
terraform output
```

### Paso 5: Desplegar Production

```bash
cd infra/aws-environments/prod

# IMPORTANTE: Revisar cuidadosamente antes de aplicar
terraform init
terraform plan -out=prod.tfplan

# Revisar el plan detalladamente
terraform show prod.tfplan

# Aplicar (requiere confirmación adicional)
terraform apply prod.tfplan

terraform output
```

### Comandos Útiles

```bash
# Ver estado actual
terraform show

# Listar recursos
terraform state list

# Ver outputs
terraform output

# Formatear código
terraform fmt -recursive

# Validar sintaxis
terraform validate

# Ver gráfico de dependencias
terraform graph | dot -Tpng > graph.png

# Destruir infraestructura (¡CUIDADO!)
terraform destroy

# Importar recurso existente
terraform import aws_instance.example i-1234567890abcdef0
```

---

## 📊 Diagrama de Flujo de Deployment

```
START
  │
  ├─► [1] Bootstrap Backend
  │    └─► terraform init/apply en aws-backend-bootstrap
  │        └─► Crear S3 + DynamoDB
  │
  ├─► [2] Actualizar Backend Config
  │    └─► Editar backend.tf en cada ambiente
  │
  ├─► [3] Deploy DEV
  │    └─► terraform init/plan/apply en dev
  │        └─► Crear VPC, ECS, ALB, (optional RDS)
  │
  ├─► [4] Deploy STAGE
  │    └─► terraform init/plan/apply en stage
  │        └─► Crear VPC, ECS, ALB, RDS
  │
  ├─► [5] Deploy PROD
  │    └─► terraform init/plan/apply en prod
  │        └─► Crear VPC, ECS, ALB, RDS Multi-AZ
  │
  └─► [6] Deploy Microservices
       └─► Build Docker images
       └─► Push to ECR
       └─► Create ECS Task Definitions
       └─► Create ECS Services
       └─► Configure Service Discovery
END
```

---

## 🔄 Workflow CI/CD Recomendado

```
Developer Push
      │
      ├─► GitHub Actions / Jenkins
      │    │
      │    ├─► Build & Test
      │    │    └─► Unit tests
      │    │    └─► Integration tests
      │    │
      │    ├─► Build Docker Images
      │    │    └─► Tag with commit SHA
      │    │
      │    ├─► Push to ECR
      │    │    └─► dev-*, stage-*, prod-*
      │    │
      │    ├─► Terraform Plan
      │    │    └─► Detect infrastructure changes
      │    │
      │    └─► Deploy
      │         ├─► DEV: Auto-deploy
      │         ├─► STAGE: Auto-deploy + smoke tests
      │         └─► PROD: Manual approval + deploy
      │
      └─► Monitoring
           └─► CloudWatch Alarms
           └─► Prometheus metrics
           └─► Grafana dashboards
```

---

## 📝 Mantenimiento y Operaciones

### Tareas Regulares

**Diarias**:
- ✅ Revisar CloudWatch Alarms
- ✅ Verificar logs de aplicación
- ✅ Monitorear costos en AWS Cost Explorer

**Semanales**:
- ✅ Revisar métricas de Prometheus/Grafana
- ✅ Verificar backups de RDS
- ✅ Actualizar security patches

**Mensuales**:
- ✅ Revisar y optimizar costos
- ✅ Actualizar versiones de Terraform modules
- ✅ Revisar IAM policies y access logs
- ✅ Disaster recovery drill

### Troubleshooting

**ECS Tasks no inician**:
```bash
# Ver logs de CloudWatch
aws logs tail /ecs/[environment]-ecommerce --follow

# Verificar task definition
aws ecs describe-tasks --cluster [cluster-name] --tasks [task-id]

# Verificar IAM roles
aws iam get-role --role-name [environment]-ecommerce-ecs-task-execution-role
```

**RDS Connection Issues**:
```bash
# Verificar security group
aws ec2 describe-security-groups --group-ids [sg-id]

# Verificar subnet group
aws rds describe-db-subnet-groups

# Test connection desde ECS task
aws ecs execute-command --cluster [cluster] --task [task-id] --command "/bin/bash" --interactive
```

**ALB Health Checks Failing**:
```bash
# Ver target health
aws elbv2 describe-target-health --target-group-arn [tg-arn]

# Ver ALB access logs
aws s3 ls s3://[alb-logs-bucket]/
```

---

## 🎓 Mejores Prácticas Implementadas

1. **Infraestructura Inmutable**: Todo definido en código
2. **Separation of Concerns**: Módulos independientes y reutilizables
3. **Least Privilege**: IAM policies mínimas necesarias
4. **Defense in Depth**: Múltiples capas de seguridad
5. **High Availability**: Multi-AZ en producción
6. **Disaster Recovery**: Backups automatizados
7. **Observability**: Logging, monitoring, tracing completo
8. **Cost Optimization**: Recursos dimensionados por ambiente
9. **Automation**: CI/CD para deployments consistentes
10. **Documentation**: Código autodocumentado + esta guía

---

## 📚 Referencias

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## 📞 Soporte

Para preguntas o issues:
1. Revisar esta documentación
2. Consultar logs de CloudWatch
3. Revisar Terraform state: `terraform show`
4. Contactar al equipo DevOps

---

**Última actualización**: 28 de noviembre de 2025  
**Versión**: 1.0.0  
**Mantenido por**: Equipo DevOps
