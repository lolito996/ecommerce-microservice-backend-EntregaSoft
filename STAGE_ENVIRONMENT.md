# 🚀 Staging Environment - AWS ECS Deployment

## 📋 Resumen del Entorno

El entorno de **staging** replica la arquitectura de producción para pruebas de integración y validación con QA antes del despliegue final.

```
Entorno:          staging
Región:           us-east-1
VPC:              vpc-03816fc7d9d383282 (10.1.0.0/16)
Cluster ECS:      stage-ecommerce-cluster
```

---

## 🌐 URLs de Acceso

### Load Balancer Principal
```
ALB DNS: stage-ecommerce-alb-326144584.us-east-1.elb.amazonaws.com
```

### Servicios Principales

| Servicio | URL | Puerto |
|----------|-----|--------|
| **API Gateway** | http://stage-ecommerce-alb-326144584.us-east-1.elb.amazonaws.com/api | 8080 |
| **Eureka Server** | http://stage-ecommerce-alb-326144584.us-east-1.elb.amazonaws.com:8761 | 8761 |
| **Prometheus** | http://stage-ecommerce-alb-326144584.us-east-1.elb.amazonaws.com:9090 | 9090 |
| **Grafana** | http://stage-ecommerce-alb-326144584.us-east-1.elb.amazonaws.com:3000 | 3000 |

---

## 🗄️ Base de Datos

### RDS PostgreSQL 15.15

```
Endpoint:         stage-ecommerce-db.caju06qosdfc.us-east-1.rds.amazonaws.com:5432
Engine:           PostgreSQL 15.15
Instance:         db.t3.small
Storage:          20 GB gp3 (auto-scaling hasta 100 GB)
Multi-AZ:         No (Single-AZ para staging)
Encrypted:        Sí
Backups:          7 días de retención
```

### Credenciales
- **Usuario:** `dbadmin`
- **Contraseña:** Almacenada en AWS Secrets Manager
- **Secret ARN:** `arn:aws:secretsmanager:us-east-1:533924338325:secret:stage-ecommerce-db-master-password-*`

#### Obtener contraseña:
```bash
aws secretsmanager get-secret-value \
  --secret-id stage-ecommerce-db-master-password \
  --query SecretString \
  --output text
```

---

## 🏗️ Infraestructura AWS

### VPC y Networking

| Componente | ID/Valor |
|------------|----------|
| VPC | vpc-03816fc7d9d383282 |
| CIDR Block | 10.1.0.0/16 |
| Availability Zones | 2 (us-east-1a, us-east-1b) |
| Public Subnets | 2 |
| Private Subnets | 2 |
| NAT Gateways | 2 (uno por AZ) |
| Internet Gateway | Sí |

### Load Balancer

| Atributo | Valor |
|----------|-------|
| Nombre | stage-ecommerce-alb |
| ARN | arn:aws:elasticloadbalancing:us-east-1:533924338325:loadbalancer/app/stage-ecommerce-alb/c0e5b52869965a80 |
| DNS | stage-ecommerce-alb-326144584.us-east-1.elb.amazonaws.com |
| Scheme | Internet-facing |
| Tipo | Application Load Balancer |

### Target Groups

| Servicio | ARN |
|----------|-----|
| API Gateway | arn:aws:elasticloadbalancing:us-east-1:533924338325:targetgroup/stage-ecommerce-api-gw-tg/95f7ddc566fbefc0 |

---

## 🐳 Microservicios (Pendientes de Despliegue)

### Servicios Backend (10 total)

1. **service-discovery** (Eureka Server) - Puerto 8761
2. **cloud-config** - Puerto 8888
3. **api-gateway** - Puerto 8080
4. **user-service** - Puerto 8081
5. **product-service** - Puerto 8082
6. **order-service** - Puerto 8083
7. **payment-service** - Puerto 8084
8. **shipping-service** - Puerto 8085
9. **favourite-service** - Puerto 8086
10. **proxy-client** - Puerto 8087

### Configuración ECS

```
Cluster:          stage-ecommerce-cluster
Launch Type:      FARGATE
CPU:              512 (.5 vCPU)
Memory:           1024 MB (1 GB)
Desired Count:    1 por servicio
```

---

## 🔐 Security Groups

### Database Security Group
- Permite tráfico PostgreSQL (5432) desde servicios ECS
- No acceso público

### ALB Security Group
- HTTP (80) desde 0.0.0.0/0
- Todos los puertos de microservicios (8080-8087, 8761, 8888, 9090, 3000)

### ECS Security Group
- Tráfico desde ALB
- Acceso saliente a RDS
- Acceso saliente a Internet (para descargas)

---

## 💰 Estimación de Costos Mensuales

| Servicio | Configuración | Costo Estimado |
|----------|---------------|----------------|
| **ECS Fargate** | 10 servicios × 0.5 vCPU × 1 GB × 24h | $75-90 |
| **ALB** | 1 ALB + tráfico | $18-25 |
| **NAT Gateways** | 2 × $32.40 | $65 |
| **RDS PostgreSQL** | db.t3.small Single-AZ + 20 GB | $35-45 |
| **CloudWatch Logs** | Logs de 10 servicios | $5-10 |
| **Secrets Manager** | 1 secreto | $0.40 |
| **Data Transfer** | Estimado | $5-15 |
| **TOTAL** | | **~$203-250/mes** |

### 💡 Optimizaciones para Staging:
- ✅ Single-AZ RDS (vs Multi-AZ en prod)
- ✅ Instancias más pequeñas (0.5 vCPU vs 1 vCPU)
- ⚠️ NAT Gateways necesarios para descargas de imágenes
- 💾 Considera pausar servicios fuera de horario de pruebas

---

## 🚀 Despliegue de Microservicios

### Paso 1: Preparar Variables de Entorno

```bash
export AWS_REGION="us-east-1"
export ENVIRONMENT="stage"
export ECS_CLUSTER="stage-ecommerce-cluster"
export DB_ENDPOINT="stage-ecommerce-db.caju06qosdfc.us-east-1.rds.amazonaws.com"
export DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id stage-ecommerce-db-master-password \
  --query SecretString --output text)
```

### Paso 2: Verificar Imágenes Docker

Asegúrate de que las imágenes de los microservicios estén disponibles en Docker Hub o ECR:

```bash
# Verificar imágenes existentes
docker images | grep ecommerce

# O listar desde Docker Hub
docker search <tu-usuario>/ecommerce
```

### Paso 3: Crear Task Definitions

Cada servicio necesita una Task Definition con:
- Imagen Docker del servicio
- Variables de entorno (DB_ENDPOINT, DB_PASSWORD, EUREKA_URL, etc.)
- Configuración de recursos (CPU: 512, Memory: 1024)
- Logs en CloudWatch

### Paso 4: Crear Servicios ECS

```bash
# Ejemplo para service-discovery
aws ecs create-service \
  --cluster stage-ecommerce-cluster \
  --service-name service-discovery \
  --task-definition service-discovery:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-zzz],assignPublicIp=DISABLED}" \
  --load-balancers targetGroupArn=arn:aws:...,containerName=service-discovery,containerPort=8761
```

---

## 🧪 Testing y Validación

### Health Checks

```bash
# Verificar API Gateway
curl http://stage-ecommerce-alb-326144584.us-east-1.elb.amazonaws.com/api/actuator/health

# Verificar Eureka
curl http://stage-ecommerce-alb-326144584.us-east-1.elb.amazonaws.com:8761/eureka/apps

# Verificar servicios registrados
curl http://stage-ecommerce-alb-326144584.us-east-1.elb.amazonaws.com:8761 | grep UP
```

### Logs

```bash
# Ver logs de un servicio
aws logs tail /ecs/stage-service-discovery --follow

# Listar todos los log groups
aws logs describe-log-groups --log-group-name-prefix /ecs/stage
```

---

## 🔧 Troubleshooting

### Servicio no inicia

1. **Verificar Task Definition:**
   ```bash
   aws ecs describe-task-definition --task-definition service-discovery:1
   ```

2. **Ver logs del contenedor:**
   ```bash
   aws logs tail /ecs/stage-service-discovery --since 1h
   ```

3. **Verificar eventos del servicio:**
   ```bash
   aws ecs describe-services --cluster stage-ecommerce-cluster --services service-discovery
   ```

### Problemas de conectividad a RDS

1. **Verificar Security Group:**
   - El SG del RDS debe permitir tráfico desde el SG de ECS en puerto 5432

2. **Probar conexión desde un contenedor:**
   ```bash
   aws ecs execute-command --cluster stage-ecommerce-cluster \
     --task <task-id> \
     --container service-discovery \
     --interactive \
     --command "/bin/bash"
   
   # Dentro del contenedor
   nc -zv stage-ecommerce-db.caju06qosdfc.us-east-1.rds.amazonaws.com 5432
   ```

### ALB no responde

1. **Verificar Target Health:**
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn arn:aws:elasticloadbalancing:us-east-1:533924338325:targetgroup/stage-ecommerce-api-gw-tg/95f7ddc566fbefc0
   ```

2. **Verificar Listener Rules:**
   ```bash
   aws elbv2 describe-listeners \
     --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:533924338325:loadbalancer/app/stage-ecommerce-alb/c0e5b52869965a80
   ```

---

## 📊 Monitoreo

### CloudWatch Dashboards

Crear dashboard personalizado para staging:

```bash
aws cloudwatch put-dashboard --dashboard-name StagingEcommerce \
  --dashboard-body file://dashboard-config.json
```

### Métricas Clave

- **ECS:** CPUUtilization, MemoryUtilization, RunningTasksCount
- **ALB:** RequestCount, TargetResponseTime, HTTPCode_Target_5XX_Count
- **RDS:** DatabaseConnections, CPUUtilization, FreeStorageSpace
- **NAT Gateway:** BytesOutToDestination, BytesInFromSource

### Alarmas Recomendadas

```bash
# Alta utilización de CPU en ECS
aws cloudwatch put-metric-alarm --alarm-name stage-ecs-high-cpu \
  --metric-name CPUUtilization --namespace AWS/ECS \
  --statistic Average --period 300 --threshold 80 \
  --comparison-operator GreaterThanThreshold

# Errores 5XX en ALB
aws cloudwatch put-metric-alarm --alarm-name stage-alb-5xx-errors \
  --metric-name HTTPCode_Target_5XX_Count --namespace AWS/ApplicationELB \
  --statistic Sum --period 60 --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

---

## 🔄 CI/CD Integration

### Variables de Entorno para GitHub Actions

```yaml
STAGE_AWS_REGION: us-east-1
STAGE_ECS_CLUSTER: stage-ecommerce-cluster
STAGE_ALB_DNS: stage-ecommerce-alb-326144584.us-east-1.elb.amazonaws.com
STAGE_DB_ENDPOINT: stage-ecommerce-db.caju06qosdfc.us-east-1.rds.amazonaws.com
STAGE_VPC_ID: vpc-03816fc7d9d383282
```

### Workflow de Despliegue

```yaml
- name: Deploy to Staging
  if: github.ref == 'refs/heads/stage'
  run: |
    aws ecs update-service \
      --cluster stage-ecommerce-cluster \
      --service ${{ matrix.service }} \
      --force-new-deployment
```

---

## 📅 Mantenimiento

### Actualizaciones Programadas

- **RDS:** Domingos 04:00-05:00 UTC
- **Backups:** Diarios 03:00-04:00 UTC

### Procedimiento de Actualización

1. Notificar al equipo QA
2. Hacer backup manual de RDS (opcional)
3. Actualizar Task Definitions con nueva imagen
4. Desplegar nuevas versiones gradualmente
5. Verificar health checks
6. Ejecutar smoke tests

---

## ⚠️ Diferencias con Producción

| Aspecto | Staging | Producción |
|---------|---------|------------|
| RDS | Single-AZ, db.t3.small | Multi-AZ, db.t3.medium |
| ECS Tasks | 0.5 vCPU, 1 GB | 1 vCPU, 2 GB |
| Desired Count | 1 por servicio | 2-3 por servicio |
| Auto Scaling | Deshabilitado | Habilitado |
| Deletion Protection | No | Sí |
| Backup Retention | 7 días | 30 días |
| SSL/TLS | No configurado | ACM Certificate |

---

## 📞 Contacto y Soporte

**Equipo de DevOps:**
- Repositorio: https://github.com/gerson05/ecommerce-microservice-backend-EntregaSoft
- Branch: `stage`
- Terraform: `infra/aws-environments/stage/`

**Comandos de Acceso Rápido:**
```bash
# SSH a VPC (requiere bastion host)
# Actualmente no configurado - usar ECS Exec para debugging

# Ver estado del cluster
aws ecs describe-clusters --clusters stage-ecommerce-cluster

# Listar servicios activos
aws ecs list-services --cluster stage-ecommerce-cluster
```

---

## ✅ Checklist de Preparación

Antes de desplegar a producción, verificar:

- [ ] Todos los microservicios desplegados y funcionando
- [ ] Health checks pasando en ALB
- [ ] Logs sin errores críticos en CloudWatch
- [ ] Pruebas de integración completadas
- [ ] Pruebas de carga con Locust ejecutadas
- [ ] QA ha validado todas las funcionalidades
- [ ] Documentación actualizada
- [ ] Plan de rollback definido
- [ ] Monitoreo y alarmas configuradas
- [ ] Equipo de soporte notificado

---

**Fecha de Despliegue:** 29 de noviembre de 2025  
**Versión:** 0.1.0  
**Estado:** ✅ Infraestructura lista - Pendiente despliegue de microservicios
