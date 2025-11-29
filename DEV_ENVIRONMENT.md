# 🔧 Entorno de Desarrollo (DEV) - E-Commerce Microservices

## 📋 Resumen del Entorno

Este documento describe el entorno de desarrollo completamente funcional desplegado en AWS ECS Fargate.

---

## ✅ Estado Actual del Entorno DEV

**Fecha de despliegue:** 28 de noviembre de 2025  
**Estado:** ✅ **COMPLETAMENTE FUNCIONAL**  
**Región AWS:** `us-east-1`  
**Cluster ECS:** `dev-ecommerce-cluster`

### Servicios Desplegados (10 microservicios)

| Servicio | Puerto | Estado | Endpoint Público | IP Interna |
|----------|--------|--------|------------------|------------|
| **API Gateway** | 8080 | ✅ Running | Via ALB | 10.0.x.x:8080 |
| **Service Discovery (Eureka)** | 8761 | ✅ Running | Privado | 10.0.10.18:8761 |
| **Cloud Config** | 9296 | ✅ Running | Privado | 10.0.x.x:9296 |
| **User Service** | 8700 | ✅ Running | ✅ `/user-service/api/users` | 10.0.x.x:8700 |
| **Product Service** | 8500 | ✅ Running | ✅ `/product-service/api/products` | 10.0.x.x:8500 |
| **Order Service** | 8300 | ✅ Running | ✅ `/order-service/api/orders` | 10.0.x.x:8300 |
| **Payment Service** | 8400 | ✅ Running | ✅ `/payment-service/api/payments` | 10.0.x.x:8400 |
| **Shipping Service** | 8600 | ✅ Running | ✅ `/shipping-service/api/shippings` | 10.0.x.x:8600 |
| **Favourite Service** | 8800 | ✅ Running | ✅ `/favourite-service/api/favourites` | 10.0.x.x:8800 |
| **Proxy Client** | 8900 | ✅ Running | ✅ `/app/api/products` | 10.0.x.x:8900 |

---

## 🌐 URLs de Acceso

### Application Load Balancer
```
http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com
```

### Endpoints de Servicios

```bash
# Base URL
export ALB_URL="http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com"

# Product Service
curl $ALB_URL/product-service/api/products

# User Service
curl $ALB_URL/user-service/api/users

# Order Service
curl $ALB_URL/order-service/api/orders

# Payment Service
curl $ALB_URL/payment-service/api/payments

# Shipping Service
curl $ALB_URL/shipping-service/api/shippings

# Favourite Service
curl $ALB_URL/favourite-service/api/favourites

# Proxy Client
curl $ALB_URL/app/api/products
```

### PowerShell (Windows)
```powershell
$alb = "http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com"

# Probar todos los servicios
Invoke-WebRequest -Uri "$alb/product-service/api/products" | Select-Object -ExpandProperty StatusCode
Invoke-WebRequest -Uri "$alb/user-service/api/users" | Select-Object -ExpandProperty StatusCode
Invoke-WebRequest -Uri "$alb/order-service/api/orders" | Select-Object -ExpandProperty StatusCode
Invoke-WebRequest -Uri "$alb/payment-service/api/payments" | Select-Object -ExpandProperty StatusCode
Invoke-WebRequest -Uri "$alb/shipping-service/api/shippings" | Select-Object -ExpandProperty StatusCode
Invoke-WebRequest -Uri "$alb/favourite-service/api/favourites" | Select-Object -ExpandProperty StatusCode
```

---

## 🏗️ Arquitectura del Entorno DEV

### Infraestructura AWS

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud (us-east-1)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  VPC: vpc-0b2c9353eedba8701 (10.0.0.0/16)                      │
│  ├── Public Subnets (2 AZs)                                     │
│  │   ├── 10.0.1.0/24 (us-east-1a)                              │
│  │   └── 10.0.2.0/24 (us-east-1b)                              │
│  │   └── ALB: dev-ecommerce-alb-1748132991                     │
│  │                                                              │
│  ├── Private Subnets (2 AZs)                                    │
│  │   ├── 10.0.10.0/24 (us-east-1a)                             │
│  │   └── 10.0.20.0/24 (us-east-1b)                             │
│  │   └── ECS Fargate Tasks (10 microservicios)                 │
│  │                                                              │
│  ├── NAT Gateways: ✅ Enabled (2 gateways)                      │
│  │   └── Permite salida de internet desde private subnets      │
│  │                                                              │
│  └── Internet Gateway: ✅ Enabled                               │
│      └── Acceso público al ALB                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🐳 Imágenes Docker

Todas las imágenes están publicadas en Docker Hub:

```
alejomunoz/api-gateway:v0.1.0
alejomunoz/cloud-config:v0.1.0
alejomunoz/favourite-service:v0.1.0
alejomunoz/order-service:v0.1.0
alejomunoz/payment-service:v0.1.0
alejomunoz/product-service:v0.1.0
alejomunoz/proxy-client:v0.1.0
alejomunoz/service-discovery:v0.1.0
alejomunoz/shipping-service:v0.1.0
alejomunoz/user-service:v0.1.0
```

---

## 📊 Monitoreo y Observabilidad

### CloudWatch Logs

**Log Group:** `/ecs/dev-ecommerce`

```bash
# Ver logs en tiempo real
aws logs tail /ecs/dev-ecommerce --follow

# Ver logs de los últimos 5 minutos
aws logs tail /ecs/dev-ecommerce --since 5m

# Buscar logs específicos
aws logs tail /ecs/dev-ecommerce --since 10m --format short | grep "ERROR"
```

```powershell
# PowerShell
aws logs tail /ecs/dev-ecommerce --follow
aws logs tail /ecs/dev-ecommerce --since 5m --format short | Select-String "ERROR"
```

### Service Discovery (Eureka)

- **URL interna:** `http://10.0.10.18:8761`
- **Dashboard:** `http://10.0.10.18:8761/` (solo accesible desde dentro del VPC)
- **Estado:** ✅ Todos los servicios registrados correctamente

---

## 💰 Costos del Entorno DEV

### Estimación Mensual: ~$150-200 USD

| Servicio | Costo/Mes | Notas |
|----------|-----------|-------|
| ALB | $16.20 | ~$0.0225/hora |
| NAT Gateways | $64.80 | 2 gateways @ $32.40 c/u |
| ECS Fargate | $50-80 | 10 tareas, CPU/Memory variable |
| Data Transfer | $10-20 | Egress data |
| CloudWatch Logs | $5-10 | Log storage + queries |
| **TOTAL** | **~$146-191** | |

---

## 📚 Documentación Adicional

- [AWS Infrastructure Guide](./infra/AWS_INFRASTRUCTURE_GUIDE.md)
- [Monitoring URLs](./infra/scripts/MONITORING_URLS.md)
- [Project Documentation](./PROJECT_DOCUMENTATION.md)
- [GitHub Environments Setup](./.github/GITHUB_ENVIRONMENTS_SETUP.md)

---

**Última actualización:** 28 de noviembre de 2025  
**Versión del Proyecto:** v0.1.0  
**Mantenido por:** Equipo DevOps
