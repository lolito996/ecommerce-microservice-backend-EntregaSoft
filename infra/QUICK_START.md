# 🚀 Guía Rápida de Despliegue AWS

## Estructura Creada

```
infra/
├── modules/                           # ✅ Módulos reutilizables
│   ├── aws-vpc/                      # VPC, subnets, NAT, IGW
│   ├── aws-ecs/                      # ECS Fargate cluster
│   ├── aws-alb/                      # Application Load Balancer
│   ├── aws-security-groups/          # Security groups
│   ├── aws-rds/                      # PostgreSQL database
│   └── aws-s3-backend/               # Remote state backend
│
├── aws-backend-bootstrap/             # ✅ Backend initialization
├── aws-environments/                  # ✅ Multi-environment config
│   ├── dev/                          # Development (10.0.0.0/16)
│   ├── stage/                        # Staging (10.1.0.0/16)
│   └── prod/                         # Production (10.2.0.0/16)
│
├── scripts/                           # ✅ Automation scripts
│   ├── init-backend.ps1
│   ├── deploy-environment.ps1
│   └── validate-terraform.ps1
│
├── README.md                          # ✅ Quick reference
├── AWS_INFRASTRUCTURE_GUIDE.md        # ✅ Complete documentation
└── ARCHITECTURE_DIAGRAMS.md           # ✅ Mermaid diagrams
```

## 🎯 Pasos de Despliegue

### 1️⃣ Configurar AWS CLI

```powershell
aws configure
# Ingresar Access Key ID, Secret Key, y region (us-east-1)
```

### 2️⃣ Inicializar Backend (una sola vez)

```powershell
cd infra/scripts
.\init-backend.ps1
```

### 3️⃣ Actualizar Backend Config

Copiar el nombre del bucket S3 del output y actualizar en:
- `infra/aws-environments/dev/main.tf`
- `infra/aws-environments/stage/main.tf`
- `infra/aws-environments/prod/main.tf`

Descomentar y actualizar la sección `backend "s3"`:

```terraform
backend "s3" {
  bucket         = "ecommerce-terraform-state-XXXXXXXX"  # ← Tu bucket
  key            = "dev/terraform.tfstate"               # ← dev/stage/prod
  region         = "us-east-1"
  dynamodb_table = "ecommerce-terraform-locks"
  encrypt        = true
}
```

### 4️⃣ Desplegar Ambiente

```powershell
# Development
.\deploy-environment.ps1 -Environment dev

# Staging
.\deploy-environment.ps1 -Environment stage

# Production
.\deploy-environment.ps1 -Environment prod
```

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

---

**Versión**: 1.0.0  
**Última actualización**: 28 de noviembre de 2025  
**Tecnologías**: Terraform, AWS (VPC, ECS, RDS, ALB, S3, CloudWatch)
