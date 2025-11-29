# ✅ Checklist de Validación - Infraestructura Terraform AWS

Use este checklist para verificar que todo está correctamente configurado antes del despliegue.

## 📋 Pre-Requisitos

- [ ] Terraform instalado (>= 1.5.0)
  ```powershell
  terraform version
  ```

- [ ] AWS CLI instalado y configurado
  ```powershell
  aws --version
  aws sts get-caller-identity
  ```

- [ ] Credenciales AWS configuradas
  ```powershell
  aws configure list
  ```

- [ ] PowerShell 7+ (para scripts)
  ```powershell
  $PSVersionTable.PSVersion
  ```

## 🔧 Validación de Módulos

### Módulo: aws-vpc
- [ ] `main.tf` contiene VPC, subnets, IGW, NAT
- [ ] `variables.tf` tiene todas las variables necesarias
- [ ] `outputs.tf` exporta vpc_id, subnet_ids
- [ ] Ejecutar: `terraform validate` en el directorio

### Módulo: aws-ecs
- [ ] `main.tf` contiene cluster, roles IAM
- [ ] CloudWatch log group configurado
- [ ] Task execution role con permisos correctos
- [ ] Ejecutar: `terraform validate`

### Módulo: aws-alb
- [ ] ALB con listeners HTTP/HTTPS
- [ ] Target groups para cada servicio
- [ ] Health checks configurados
- [ ] Ejecutar: `terraform validate`

### Módulo: aws-security-groups
- [ ] SG para ALB (80, 443)
- [ ] SG para ECS (interno + desde ALB)
- [ ] SG para RDS (5432 desde ECS)
- [ ] Ejecutar: `terraform validate`

### Módulo: aws-rds
- [ ] RDS PostgreSQL configurado
- [ ] Secrets Manager para password
- [ ] Backup configuration
- [ ] Ejecutar: `terraform validate`

### Módulo: aws-s3-backend
- [ ] S3 bucket con versionado
- [ ] DynamoDB table para locks
- [ ] IAM policy correcta
- [ ] Ejecutar: `terraform validate`

## 🏗️ Validación de Ambientes

### Development
- [ ] `main.tf` configurado correctamente
- [ ] Backend S3 configurado (descomentar)
- [ ] Variables en `variables.tf` correctas
- [ ] VPC CIDR: 10.0.0.0/16
- [ ] NAT Gateway deshabilitado (ahorro)
- [ ] RDS opcional (default: false)
- [ ] Ejecutar: `terraform init && terraform validate`

### Staging
- [ ] `main.tf` configurado correctamente
- [ ] Backend S3 configurado (key: stage/terraform.tfstate)
- [ ] Variables en `variables.tf` correctas
- [ ] VPC CIDR: 10.1.0.0/16
- [ ] NAT Gateway habilitado
- [ ] RDS habilitado (Single-AZ)
- [ ] VPC Flow Logs habilitados
- [ ] Ejecutar: `terraform init && terraform validate`

### Production
- [ ] `main.tf` configurado correctamente
- [ ] Backend S3 configurado (key: prod/terraform.tfstate)
- [ ] Variables en `variables.tf` correctas
- [ ] VPC CIDR: 10.2.0.0/16
- [ ] 3 Availability Zones
- [ ] NAT Gateway habilitado (3)
- [ ] RDS Multi-AZ habilitado
- [ ] HTTPS habilitado
- [ ] CloudWatch Alarms configuradas
- [ ] Deletion protection habilitado
- [ ] Ejecutar: `terraform init && terraform validate`

## 🔄 Backend Bootstrap

- [ ] `aws-backend-bootstrap/main.tf` existe
- [ ] S3 bucket name será único (usa random_string)
- [ ] DynamoDB table configurada
- [ ] Outputs muestran instrucciones
- [ ] Ejecutar: `.\scripts\init-backend.ps1`
- [ ] Anotar S3 bucket name del output
- [ ] Anotar DynamoDB table name

## 📜 Scripts de Automatización

### init-backend.ps1
- [ ] Script existe y es ejecutable
- [ ] Verifica prerequisites
- [ ] Ejecuta terraform init/plan/apply
- [ ] Genera archivo de configuración
- [ ] Muestra instrucciones claras

### deploy-environment.ps1
- [ ] Script existe y es ejecutable
- [ ] Acepta parámetro -Environment
- [ ] Valida credenciales AWS
- [ ] Ejecuta terraform plan
- [ ] Muestra outputs al finalizar
- [ ] Guarda deployment-info.json

### validate-terraform.ps1
- [ ] Script existe y es ejecutable
- [ ] Valida formato (terraform fmt)
- [ ] Valida sintaxis (terraform validate)
- [ ] Ejecuta TFLint (opcional)
- [ ] Muestra resumen de resultados

## 📚 Documentación

- [ ] README.md existe y está completo
- [ ] QUICK_START.md con guía de 4 pasos
- [ ] AWS_INFRASTRUCTURE_GUIDE.md completo (1200+ líneas)
- [ ] ARCHITECTURE_DIAGRAMS.md con 10 diagramas Mermaid
- [ ] PROJECT_SUMMARY.md con resumen ejecutivo
- [ ] .gitignore configurado para Terraform

## 🧪 Testing

### Test Manual de Validación
```powershell
# En directorio infra/scripts/
.\validate-terraform.ps1 -Target all
```

- [ ] Todos los módulos pasan validación
- [ ] Todos los ambientes pasan validación
- [ ] Backend bootstrap pasa validación
- [ ] Sin errores de sintaxis
- [ ] Formato correcto (terraform fmt)

### Test de Backend
```powershell
cd ../aws-backend-bootstrap
terraform init
terraform plan
```

- [ ] Init exitoso
- [ ] Plan muestra recursos a crear
- [ ] Sin errores de configuración

### Test de Ambiente Dev
```powershell
cd ../aws-environments/dev
terraform init
terraform plan
```

- [ ] Init exitoso (o pide configurar backend)
- [ ] Plan exitoso
- [ ] Recursos correctos en plan

## 🔐 Seguridad

- [ ] No hay credenciales hardcoded en código
- [ ] IAM roles usan AssumeRole
- [ ] Security groups son restrictivos
- [ ] RDS tiene encryption enabled
- [ ] S3 backend tiene encryption
- [ ] Secrets Manager para passwords
- [ ] VPC Flow Logs en stage/prod
- [ ] .gitignore protege archivos sensibles

## 💰 Costos

- [ ] Entiendes los costos estimados:
  - Dev: ~$50-100/mes
  - Stage: ~$200-300/mes
  - Prod: ~$500-800/mes

- [ ] NAT Gateways deshabilitados en dev (ahorro)
- [ ] RDS opcional en dev
- [ ] Configuración optimizada por ambiente

## 🚀 Pre-Deployment

Antes de desplegar a AWS:

- [ ] Revisado toda la configuración
- [ ] Validado todos los módulos
- [ ] Configurado backend remoto
- [ ] Actualizado variables si es necesario
- [ ] Backup de estado actual (si existe)
- [ ] Aprobación de costos (especialmente prod)
- [ ] Plan de rollback definido

## 📊 Post-Deployment

Después del deployment:

- [ ] Verificar outputs de Terraform
- [ ] Revisar recursos creados en AWS Console
- [ ] Verificar ALB DNS funciona
- [ ] Verificar conectividad a RDS
- [ ] Revisar CloudWatch Logs
- [ ] Verificar state en S3
- [ ] Probar health checks
- [ ] Documentar IPs/DNS importantes

## 🎯 Requisitos del Proyecto (20%)

- [ ] ✅ Infraestructura configurada con Terraform
- [ ] ✅ Estructura modular implementada
- [ ] ✅ Múltiples ambientes (dev, stage, prod)
- [ ] ✅ Documentación con diagramas
- [ ] ✅ Backend remoto implementado

## 🏁 Ready to Deploy?

Si todos los checkboxes arriba están marcados, estás listo para:

```powershell
# Paso 1: Inicializar backend
cd infra/scripts
.\init-backend.ps1

# Paso 2: Actualizar backend config en cada ambiente
# (Descomentar y actualizar bucket name en main.tf)

# Paso 3: Desplegar dev
.\deploy-environment.ps1 -Environment dev

# Paso 4: Desplegar stage
.\deploy-environment.ps1 -Environment stage

# Paso 5: Desplegar prod (con cuidado!)
.\deploy-environment.ps1 -Environment prod
```

---

## 📝 Notas Adicionales

**Consejos**:
- Empieza con dev, luego stage, finalmente prod
- Usa `-Plan` flag para ver cambios sin aplicar
- Mantén backups del state
- Documenta cualquier cambio manual
- Revisa costos regularmente en AWS Cost Explorer

**En caso de error**:
1. Leer el mensaje de error completo
2. Verificar logs de CloudWatch
3. Ejecutar `terraform show` para ver estado
4. Consultar AWS_INFRASTRUCTURE_GUIDE.md
5. Verificar credenciales y permisos AWS

---

**Última actualización**: 28 de noviembre de 2025  
**Versión**: 1.0.0
