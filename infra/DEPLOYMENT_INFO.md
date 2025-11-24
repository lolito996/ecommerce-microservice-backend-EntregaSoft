# 🚀 Despliegue de Microservicios en AWS EKS - Staging
## ✅ Despliegue Completado Exitosamente

## 📊 Información del Cluster
- **Cluster:** ecom-staging-eks
- **Región:** us-east-1
- **Kubernetes Version:** 1.28
- **Namespace:** microservices-staging
- **Nodos:** 2x t3.medium (ip-10-0-10-225, ip-10-0-20-242)
- **VPC CIDR:** 10.0.0.0/16
- **Subnets:** 2 públicas + 2 privadas
- **NAT Gateways:** 2 (alta disponibilidad)

## 🌐 URLs de Acceso Público

### 🔗 API Gateway (Punto de Entrada Principal)
```
http://a684a944311054f8faa8c6af7a851ba0-24347457.us-east-1.elb.amazonaws.com
```
**Estado:** ✅ Funcionando
**Health Check:** `GET /actuator/health` ✅
**Servicios Registrados en Eureka:** 6

### 📊 Monitoreo - Grafana
```
http://aa3ba54dfc32343379121c24a557823a-703263735.us-east-1.elb.amazonaws.com
```
**Estado:** ✅ Funcionando
**Usuario:** admin / admin
**Dashboards:** Disponibles

### 🔍 Distributed Tracing - Zipkin
```
http://a69e0aa1986e6457fae681e617ae4ffc-2007257503.us-east-1.elb.amazonaws.com
```
**Estado:** ✅ Funcionando
**Servicios Rastreados:** api-gateway, cloud-config, product-service, service-discovery, user-service
**Sampling:** 100% (configurado para staging)

## 📦 Servicios Desplegados

### ✅ Servicios Core (Infraestructura)
| Servicio | Estado | Pods | Función |
|----------|--------|------|----------|
| api-gateway | ✅ READY 1/1 | Running | Gateway principal, enrutamiento |
| service-discovery | ✅ READY 1/1 | Running | Eureka Server, descubrimiento de servicios |
| cloud-config | ✅ READY 1/1 | Running | Servidor de configuración centralizada |
| proxy-client | ✅ READY 1/1 | Running | Cliente proxy para comunicación |

### ✅ Microservicios de Negocio
| Servicio | Estado | Pods | Endpoint Funcional | Datos |
|----------|--------|------|-------------------|-------|
| product-service | ✅ READY 1/1 | Running | `/product-service/api/products` | ✅ 4 productos |
| user-service | ✅ READY 1/1 | Running | `/user-service/api/users` | ✅ Operativo |
| order-service | ✅ READY 1/1 | Running | `/order-service/api/orders` | ✅ Operativo |
| shipping-service | ✅ READY 1/1 | Running | `/shipping-service/api/shippings` | ✅ Operativo |
| favourite-service | ⚠️ 0/1 Running | Iniciando | `/favourite-service/api/favourites` | ⏳ Depende de cloud-config |
| payment-service | ⚠️ 0/1 Running | Iniciando | `/payment-service/api/payments` | ⏳ Depende de cloud-config |

### ✅ Observabilidad
| Servicio | Estado | Pods | Puerto | Función |
|----------|--------|------|--------|----------|
| grafana | ✅ READY 1/1 | Running | 3000 | Dashboards y visualización |
| zipkin | ✅ READY 1/1 | Running | 9411 | Trazas distribuidas |

## 🧪 Endpoints Probados y Funcionales

### ✅ Product Service
```bash
curl http://a684a944311054f8faa8c6af7a851ba0-24347457.us-east-1.elb.amazonaws.com/product-service/api/products
```
**Resultado:** ✅ Retorna 4 productos (asus, hp, Armani, GTA)

### ✅ User Service
```bash
curl http://a684a944311054f8faa8c6af7a851ba0-24347457.us-east-1.elb.amazonaws.com/user-service/api/users
```
**Resultado:** ✅ Retorna lista de usuarios

### ✅ Order Service
```bash
curl http://a684a944311054f8faa8c6af7a851ba0-24347457.us-east-1.elb.amazonaws.com/order-service/api/orders
```
**Resultado:** ✅ Retorna órdenes

### ✅ Shipping Service
```bash
curl http://a684a944311054f8faa8c6af7a851ba0-24347457.us-east-1.elb.amazonaws.com/shipping-service/api/shippings
```
**Resultado:** ✅ Retorna envíos

### ✅ Health Check API Gateway
```bash
curl http://a684a944311054f8faa8c6af7a851ba0-24347457.us-east-1.elb.amazonaws.com/actuator/health
```
**Resultado:** ✅ Status UP, Circuit Breakers funcionando, 6 servicios en Eureka

## 🔧 Comandos Útiles

### Verificar Estado del Cluster
```bash
# Conectar a EKS
aws eks update-kubeconfig --region us-east-1 --name ecom-staging-eks

# Ver nodos
kubectl get nodes

# Ver todos los pods
kubectl get pods -n microservices-staging

# Ver servicios y LoadBalancers
kubectl get svc -n microservices-staging
```

### Monitoreo de Servicios
```bash
# Ver logs de un servicio
kubectl logs -f <pod-name> -n microservices-staging

# Ver logs de api-gateway
kubectl logs -f api-gateway-845547fb96-7jxpd -n microservices-staging

# Ver eventos del namespace
kubectl get events -n microservices-staging --sort-by='.lastTimestamp'
```

### Escalamiento
```bash
# Escalar un servicio
kubectl scale deployment product-service --replicas=3 -n microservices-staging

# Ver estado del deployment
kubectl rollout status deployment/product-service -n microservices-staging
```

### Debugging
```bash
# Ejecutar comando en un pod
kubectl exec -it <pod-name> -n microservices-staging -- sh

# Ver variables de entorno
kubectl exec <pod-name> -n microservices-staging -- env

# Describir un pod
kubectl describe pod <pod-name> -n microservices-staging
```

## 🔍 Zipkin - Distributed Tracing

### Cómo Ver Trazas
1. Accede a: http://a69e0aa1986e6457fae681e617ae4ffc-2007257503.us-east-1.elb.amazonaws.com
2. Haz clic en **"Run Query"**
3. Verás lista de trazas con tiempos de respuesta
4. Haz clic en una traza para ver el flujo completo

### Ver Mapa de Dependencias
1. Haz clic en **"Dependencies"** (menú superior)
2. Verás un grafo con:
   - Conexiones entre servicios
   - Dirección de las llamadas
   - Volumen de peticiones

### Servicios Rastreados
- ✅ api-gateway
- ✅ cloud-config
- ✅ product-service
- ✅ service-discovery
- ✅ user-service

## 📝 Configuraciones Importantes

### ConfigMap (micro-config)
```yaml
EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE: "http://service-discovery.microservices-staging.svc.cluster.local:8761/eureka/"
SPRING_ZIPKIN_BASE_URL: "http://zipkin.microservices-staging.svc.cluster.local:9411"
SPRING_SLEUTH_SAMPLER_PROBABILITY: "1.0"  # 100% sampling para staging
SPRING_CLOUD_CONFIG_URI: "http://cloud-config.microservices-staging.svc.cluster.local:9296"
```

### Servicios Kubernetes Internos
- `service-discovery:8761` - Eureka Server
- `cloud-config:9296` - Config Server
- `zipkin:9411` - Zipkin Server (interno)
- Todos los microservicios usan nombres DNS internos

### Probes Configurados
- **readinessProbe:** 180 segundos (para servicios lentos)
- **livenessProbe:** 210 segundos
- **Resources:** 256Mi-512Mi RAM, 250m-500m CPU

## 🐛 Problemas Resueltos Durante el Despliegue

### 1. Service Discovery no encontrado
**Problema:** Servicios no podían registrarse en Eureka
**Solución:** Crear servicio ClusterIP para `service-discovery`

### 2. Zipkin sin trazas
**Problema:** Zipkin vacío, servicios no enviaban trazas
**Solución:** 
- Crear servicio ClusterIP interno `zipkin:9411`
- Configurar `SPRING_SLEUTH_SAMPLER_PROBABILITY=1.0`
- Cambiar URL a nombre DNS completo sin barra final

### 3. Pods en CrashLoopBackOff
**Problema:** Servicios se reiniciaban constantemente
**Solución:** Aumentar tiempos de readiness/liveness probes a 180/210 segundos

### 4. Variables no sustituidas en manifiestos
**Problema:** ${NAMESPACE}, ${REGISTRY}, ${IMAGE_TAG} no reemplazados
**Solución:** Usar PowerShell para sustituir variables antes de `kubectl apply`

## 💰 Costos Estimados (Staging)

| Recurso | Especificación | Costo Mensual |
|---------|----------------|---------------|
| EKS Cluster | Control Plane | ~$73 |
| EC2 Instances | 2x t3.medium | ~$60 |
| NAT Gateways | 2x NAT + Data Transfer | ~$65 |
| LoadBalancers | 3x Application LB | ~$50 |
| EBS Volumes | 80GB gp3 x2 | ~$16 |
| **Total** | | **~$264/mes** |

### Reducir Costos
- Usar 1 NAT Gateway: ahorra ~$32/mes (reduce disponibilidad)
- Instancias t3.small: ahorra ~$30/mes (reduce rendimiento)
- Apagar staging fuera de horario: ahorra ~50%

## 🔄 Actualizar Despliegue

### Flujo Completo
```bash
# 1. Hacer cambios en el código
cd <microservicio>

# 2. Compilar con Maven
./mvnw clean package -DskipTests

# 3. Construir nueva imagen Docker
cd ..
docker compose build <servicio>

# 4. Tagear y subir a Docker Hub
docker tag <servicio>:latest alejomunoz/<servicio>:latest
docker push alejomunoz/<servicio>:latest

# 5. Reiniciar deployment en Kubernetes
kubectl rollout restart deployment <servicio> -n microservices-staging

# 6. Verificar actualización
kubectl rollout status deployment/<servicio> -n microservices-staging
kubectl get pods -n microservices-staging
```

### Script de Actualización Rápida
```powershell
# update-service.ps1
param([string]$service)

Write-Host "Actualizando $service..." -ForegroundColor Green

# Compilar
Set-Location $service
.\mvnw clean package -DskipTests
Set-Location ..

# Construir y subir imagen
docker compose build $service
docker push alejomunoz/$service:latest

# Reiniciar en Kubernetes
kubectl rollout restart deployment $service -n microservices-staging
kubectl rollout status deployment/$service -n microservices-staging

Write-Host "✅ $service actualizado" -ForegroundColor Green
```

## 📚 Recursos y Referencias

### Imágenes Docker
- **Registry:** Docker Hub
- **Usuario:** alejomunoz
- **Imágenes:** 
  - alejomunoz/api-gateway:latest
  - alejomunoz/cloud-config:latest
  - alejomunoz/service-discovery:latest
  - alejomunoz/product-service:latest
  - alejomunoz/user-service:latest
  - alejomunoz/order-service:latest
  - alejomunoz/shipping-service:latest
  - alejomunoz/favourite-service:latest
  - alejomunoz/payment-service:latest
  - alejomunoz/proxy-client:latest

### Terraform State
- **Backend:** S3
- **Bucket:** ecom-terraform-state-backend-533924338325
- **Lock Table:** ecom-terraform-state-lock (DynamoDB)
- **Region:** us-east-1

### Archivos Importantes
- `DEPLOYMENT_INFO.md` - Esta documentación
- `AWS_ENDPOINTS.md` - URLs de endpoints
- `infra/terraform/` - Infraestructura como código
- `k8s/base/` - Manifiestos de Kubernetes
- `push-images.ps1` - Script para subir imágenes
- `compose.yml` - Docker Compose para build

## 🎯 Próximos Pasos

### Mejoras Recomendadas
1. **CI/CD:** Implementar pipeline de Jenkins/GitHub Actions
2. **Monitoreo:** Configurar dashboards en Grafana
3. **Alertas:** Configurar alertas de Prometheus
4. **Ingress:** Usar AWS ALB Ingress Controller en lugar de múltiples LB
5. **Secrets:** Migrar a AWS Secrets Manager
6. **Base de Datos:** Agregar RDS para persistencia
7. **Cache:** Implementar Redis/ElastiCache
8. **Auto-scaling:** Configurar HPA (Horizontal Pod Autoscaler)

### Ambiente Production
- Desplegar con `terraform apply` en `environments/prod`
- 3 nodos t3.large
- Multi-AZ para alta disponibilidad
- Configurar sampling de Zipkin al 10%
- Implementar backups automáticos

