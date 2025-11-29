# URLs de Monitoreo y Acceso - Microservicios E-Commerce

## 🌐 URLs Públicas (ALB)

**Application Load Balancer:**
```
http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com
```

### APIs Disponibles:

| Servicio | Endpoint | Status |
|----------|----------|--------|
| Product Service | `/product-service/api/products` | ✅ 200 OK |
| User Service | `/user-service/api/users` | ✅ 200 OK |
| Order Service | `/order-service/api/orders` | ✅ 200 OK |
| Payment Service | `/payment-service/api/payments` | ✅ 200 OK |
| Shipping Service | `/shipping-service/api/shippings` | ✅ 200 OK |
| Favourite Service | `/favourite-service/api/favourites` | ✅ 200 OK |
| Proxy Client | `/app/api/products` | ✅ 200 OK |

---

## 🔍 Eureka Service Discovery

**IP Interna:** `http://10.0.10.18:8761`

**Dashboard:** `http://10.0.10.18:8761/`

⚠️ **Nota:** Eureka NO está expuesto públicamente (por seguridad). Está en una subnet privada.

### Opciones para acceder a Eureka:

#### Opción 1: AWS Systems Manager Session Manager
```powershell
# 1. Obtener el Task ID de cualquier servicio
$taskArn = aws ecs list-tasks --cluster dev-ecommerce-cluster --service-name dev-product-service --query 'taskArns[0]' --output text

# 2. Obtener el Runtime ID del contenedor
$containerId = aws ecs describe-tasks --cluster dev-ecommerce-cluster --tasks $taskArn --query 'tasks[0].containers[0].runtimeId' --output text

# 3. Iniciar sesión
aws ecs execute-command --cluster dev-ecommerce-cluster --task $taskArn --container product-service --interactive --command "/bin/sh"

# 4. Desde dentro del contenedor:
curl http://10.0.10.18:8761/eureka/apps
```

#### Opción 2: Verificar registro en CloudWatch Logs
```powershell
# Ver logs de un servicio para confirmar registro en Eureka
aws logs tail /ecs/dev-ecommerce --since 5m --format short | Select-String "Registered application"
```

#### Opción 3: Exponer Eureka temporalmente (NO RECOMENDADO para producción)
Puedes agregar una regla en el ALB para redirigir `/eureka` al servicio de Eureka.

---

## 📊 Zipkin (Distributed Tracing)

⚠️ **IMPORTANTE:** Zipkin actualmente **NO está desplegado** en la infraestructura de AWS.

### Para desplegar Zipkin:

#### 1. Crear Task Definition para Zipkin:
```json
{
  "family": "dev-zipkin",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::533924338325:role/dev-ecommerce-ecs-task-execution-role",
  "taskRoleArn": "arn:aws:iam::533924338325:role/dev-ecommerce-ecs-task-role",
  "containerDefinitions": [{
    "name": "zipkin",
    "image": "openzipkin/zipkin:latest",
    "portMappings": [{
      "containerPort": 9411,
      "protocol": "tcp"
    }],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/dev-ecommerce",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "zipkin"
      }
    }
  }]
}
```

#### 2. Crear servicio ECS:
```powershell
aws ecs create-service `
  --cluster dev-ecommerce-cluster `
  --service-name dev-zipkin `
  --task-definition dev-zipkin `
  --desired-count 1 `
  --launch-type FARGATE `
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}"
```

#### 3. Actualizar microservicios:
Los microservicios ya tienen configurado Zipkin con la variable de entorno:
```yaml
spring:
  zipkin:
    base-url: ${SPRING_ZIPKIN_BASE_URL:http://localhost:9411/}
```

Solo necesitas actualizar las task definitions con:
```
SPRING_ZIPKIN_BASE_URL=http://<zipkin-ip>:9411/
```

---

## 📝 Verificación Rápida

### Verificar todos los servicios están funcionando:
```powershell
$alb = "http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com"
$endpoints = @("/product-service/api/products", "/user-service/api/users", "/order-service/api/orders", "/payment-service/api/payments", "/shipping-service/api/shippings", "/favourite-service/api/favourites", "/app/api/products")

foreach ($e in $endpoints) {
    try {
        $r = Invoke-WebRequest -Uri "$alb$e" -UseBasicParsing -TimeoutSec 5
        Write-Host "✓ $e - $($r.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "✗ $e - Error" -ForegroundColor Red
    }
}
```

### Verificar logs de Eureka en CloudWatch:
```powershell
# Ver registros de servicios en Eureka
aws logs tail /ecs/dev-ecommerce --since 10m --format short | Select-String "Registered application|DiscoveryClient_"

# Ver que servicios están activos
aws logs tail /ecs/dev-ecommerce --since 5m --format short | Select-String "Registering application" | Select-Object -Last 20
```

---

## 🔐 Información de Seguridad

- **VPC ID:** `vpc-0b2c9353eedba8701`
- **Cluster:** `dev-ecommerce-cluster`
- **Eureka IP:** `10.0.10.18:8761`
- **Subnets:** Privadas (sin acceso directo desde internet)
- **ALB:** Único punto de entrada público

---

## ⚡ Próximos Pasos Sugeridos

1. ✅ **Todos los microservicios están funcionando correctamente**
2. ⏳ **Desplegar Zipkin** para trazabilidad distribuida
3. 📊 **Configurar Prometheus + Grafana** para métricas (ya están los endpoints `/actuator/prometheus`)
4. 🔒 **Configurar HTTPS** en el ALB con certificado SSL
5. 🔐 **Implementar autenticación** (JWT tokens)

---

**Última actualización:** 28 de noviembre de 2025
