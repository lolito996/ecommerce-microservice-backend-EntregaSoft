# 🚀 Quick Start - Acceso Rápido al Entorno DEV

## ✅ Estado del Sistema

**Última actualización:** 28 de noviembre de 2025  
**Estado:** ✅ **TODOS LOS SERVICIOS OPERATIVOS**

---

## 🌐 URL del Entorno DEV

```
http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com
```

---

## 🧪 Prueba Rápida (Copia y Pega)

### PowerShell (Windows)
```powershell
# Definir URL base
$alb = "http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com"

# Probar Product Service
Invoke-WebRequest -Uri "$alb/product-service/api/products" | Select-Object StatusCode, @{N='Service';E={'Product Service'}}

# Probar User Service
Invoke-WebRequest -Uri "$alb/user-service/api/users" | Select-Object StatusCode, @{N='Service';E={'User Service'}}

# Probar Order Service
Invoke-WebRequest -Uri "$alb/order-service/api/orders" | Select-Object StatusCode, @{N='Service';E={'Order Service'}}
```

### Bash (Linux/Mac)
```bash
# Definir URL base
ALB="http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com"

# Probar servicios
curl -s -o /dev/null -w "Product Service: %{http_code}\n" $ALB/product-service/api/products
curl -s -o /dev/null -w "User Service: %{http_code}\n" $ALB/user-service/api/users
curl -s -o /dev/null -w "Order Service: %{http_code}\n" $ALB/order-service/api/orders
```

---

## 📊 Servicios Disponibles

| Servicio | Endpoint | Status |
|----------|----------|--------|
| **Product Service** | `/product-service/api/products` | ✅ 200 OK |
| **User Service** | `/user-service/api/users` | ✅ 200 OK |
| **Order Service** | `/order-service/api/orders` | ✅ 200 OK |
| **Payment Service** | `/payment-service/api/payments` | ✅ 200 OK |
| **Shipping Service** | `/shipping-service/api/shippings` | ✅ 200 OK |
| **Favourite Service** | `/favourite-service/api/favourites` | ✅ 200 OK |
| **Proxy Client** | `/app/api/products` | ✅ 200 OK |

---

## 📚 Documentación Completa

- **[📋 Entorno DEV Completo](./DEV_ENVIRONMENT.md)** - Documentación detallada del entorno
- **[🌍 GitHub Environments Setup](./.github/GITHUB_ENVIRONMENTS_SETUP.md)** - Configurar CI/CD
- **[🏗️ AWS Infrastructure Guide](./infra/AWS_INFRASTRUCTURE_GUIDE.md)** - Arquitectura AWS
- **[📊 Monitoring URLs](./infra/scripts/MONITORING_URLS.md)** - URLs de monitoreo

---

## 🔐 Acceso AWS

**Región:** `us-east-1`  
**Cluster:** `dev-ecommerce-cluster`  
**VPC:** `vpc-0b2c9353eedba8701`

### Ver Logs
```bash
aws logs tail /ecs/dev-ecommerce --follow
```

### Ver Servicios
```bash
aws ecs list-services --cluster dev-ecommerce-cluster
```

---

## 🎯 Próximos Pasos

1. ✅ **Probar los servicios** - Usa los comandos de arriba
2. 📖 **Leer documentación completa** - [DEV_ENVIRONMENT.md](./DEV_ENVIRONMENT.md)
3. 🔧 **Configurar GitHub Environments** - [GITHUB_ENVIRONMENTS_SETUP.md](./.github/GITHUB_ENVIRONMENTS_SETUP.md)
4. 🚀 **Desplegar cambios** - Push a `develop` para auto-deploy

---

## 🆘 ¿Necesitas Ayuda?

- **Documentación:** Ver [DEV_ENVIRONMENT.md](./DEV_ENVIRONMENT.md)
- **Troubleshooting:** Ver sección de troubleshooting en la documentación
- **CloudWatch Logs:** `aws logs tail /ecs/dev-ecommerce --follow`

---

**¿Todo funcionando?** ✅ ¡Perfecto! Lee la documentación completa para más detalles.
