# Terraform Infrastructure - E-Commerce Microservices

## 📁 Estructura del Proyecto

```
infra/
├── modules/                      # Módulos reutilizables
│   ├── aws-vpc/                 # VPC, subnets, NAT, IGW
│   ├── aws-ecs/                 # ECS cluster y roles IAM
│   ├── aws-alb/                 # Application Load Balancer
│   ├── aws-security-groups/     # Security groups
│   ├── aws-rds/                 # Base de datos PostgreSQL
│   └── aws-s3-backend/          # Backend remoto S3+DynamoDB
│
├── aws-backend-bootstrap/        # Inicialización del backend
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── aws-environments/             # Configuraciones por ambiente
│   ├── dev/                     # Desarrollo
│   ├── stage/                   # Staging/QA
│   └── prod/                    # Producción
│
├── scripts/                      # Scripts de automatización
│   ├── init-backend.ps1         # Inicializar backend
│   ├── deploy-environment.ps1   # Desplegar ambiente
│   └── validate-terraform.ps1   # Validar configuración
│
└── AWS_INFRASTRUCTURE_GUIDE.md   # Documentación completa
```

## 🚀 Quick Start

### 1. Prerequisitos

```powershell
# Instalar Terraform
choco install terraform

# Instalar AWS CLI
choco install awscli

# Configurar credenciales AWS
aws configure
```

### 2. Inicializar Backend (solo una vez)

```powershell
cd infra/scripts
.\init-backend.ps1
```

Esto crea:
- S3 bucket para Terraform state
- DynamoDB table para state locking
- IAM policies necesarias

### 3. Actualizar Backend Config

Después de ejecutar `init-backend.ps1`, copia el bucket name y actualiza en cada ambiente:

```terraform
# En infra/aws-environments/{dev,stage,prod}/main.tf
terraform {
  backend "s3" {
    bucket         = "ecommerce-terraform-state-XXXXXXXX"  # Actualizar aquí
    key            = "{environment}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ecommerce-terraform-locks"
    encrypt        = true
  }
}
```

### 4. Desplegar Ambiente

```powershell
# Development
.\deploy-environment.ps1 -Environment dev

# Staging
.\deploy-environment.ps1 -Environment stage

# Production (requiere confirmación)
.\deploy-environment.ps1 -Environment prod
```

## 🔧 Comandos Útiles

```powershell
# Validar configuración
.\validate-terraform.ps1

# Ver plan sin aplicar
.\deploy-environment.ps1 -Environment dev -Plan

# Auto-aprobar (útil para CI/CD)
.\deploy-environment.ps1 -Environment dev -AutoApprove

# Destruir ambiente
.\deploy-environment.ps1 -Environment dev -Destroy
```

## 🏗️ Arquitectura

### Componentes Principales

**Networking**:
- VPC aislada por ambiente
- Subnets públicas (ALB, NAT)
- Subnets privadas (ECS, RDS)
- Internet Gateway + NAT Gateways

**Compute**:
- ECS Fargate (serverless)
- Microservicios:
  - API Gateway (8080)
  - Service Discovery/Eureka (8761)
  - User Service (8700)
  - Product Service (8500)
  - Order Service (8300)
  - Payment Service (8400)
  - Shipping Service (8600)
  - Favourite Service (8800)
  - Monitoring (Prometheus, Grafana)
  - Tracing (Zipkin)

**Database**:
- RDS PostgreSQL
- Multi-AZ en producción
- Automated backups
- Secrets Manager para credenciales

**Load Balancing**:
- Application Load Balancer
- Target groups por servicio
- Health checks
- HTTPS (prod)

## 📊 Ambientes

| Ambiente | VPC CIDR | AZs | NAT | RDS | Costo/mes |
|----------|----------|-----|-----|-----|-----------|
| Dev | 10.0.0.0/16 | 2 | ❌ | Opcional | ~$50-100 |
| Stage | 10.1.0.0/16 | 2 | ✅ | Single-AZ | ~$200-300 |
| Prod | 10.2.0.0/16 | 3 | ✅ | Multi-AZ | ~$500-800 |

## 🔐 Seguridad

- **VPC Isolation**: Ambientes completamente separados
- **Security Groups**: Reglas restrictivas
- **IAM Roles**: Sin credenciales hardcoded
- **Encryption**: RDS y S3 encriptados
- **Secrets Manager**: Passwords seguros
- **VPC Flow Logs**: Auditoría de red (stage/prod)

## 📝 Documentación Completa

Ver [AWS_INFRASTRUCTURE_GUIDE.md](./AWS_INFRASTRUCTURE_GUIDE.md) para:
- Diagramas detallados de arquitectura
- Costos estimados
- Guía de troubleshooting
- Mejores prácticas
- Mantenimiento y operaciones

## 🧪 Testing

```powershell
# Validar todos los ambientes
.\validate-terraform.ps1 -Target all

# Validar ambiente específico
.\validate-terraform.ps1 -Target dev

# Validar solo backend
.\validate-terraform.ps1 -Target backend
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths: ['infra/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Terraform Init
        run: terraform init
        working-directory: infra/aws-environments/dev
        
      - name: Terraform Plan
        run: terraform plan
        working-directory: infra/aws-environments/dev
        
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
        working-directory: infra/aws-environments/dev
```

## 🆘 Troubleshooting

### Error: Backend not configured
```powershell
# Ejecutar init-backend.ps1 primero
.\scripts\init-backend.ps1

# Luego actualizar backend config en main.tf
```

### Error: AWS credentials not found
```powershell
aws configure
# Ingresar Access Key ID y Secret Access Key
```

### Error: Terraform init failed
```powershell
# Limpiar archivos temporales
Remove-Item -Recurse -Force .terraform
Remove-Item .terraform.lock.hcl

# Reintentar
terraform init
```

### Ver logs de ECS
```powershell
aws logs tail /ecs/{environment}-ecommerce --follow
```

### Ver estado de RDS
```powershell
aws rds describe-db-instances --db-instance-identifier {environment}-ecommerce-db
```

## 📚 Referencias

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 👥 Soporte

Para preguntas o problemas:
1. Consultar [AWS_INFRASTRUCTURE_GUIDE.md](./AWS_INFRASTRUCTURE_GUIDE.md)
2. Revisar logs en CloudWatch
3. Verificar Terraform state: `terraform show`
4. Contactar al equipo DevOps

---

**Versión**: 1.0.0  
**Última actualización**: 28 de noviembre de 2025
