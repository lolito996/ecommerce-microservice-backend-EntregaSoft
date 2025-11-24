# ⏸️ Pausar y ▶️ Reactivar Recursos AWS

## 📊 Estado Actual: PAUSADO

### ✅ Recursos Pausados
- **Nodos EC2:** 0 (escalado a 0)
- **LoadBalancers:** Eliminados (api-gateway, grafana, zipkin)
- **Pods:** Sin ejecutar (no hay nodos)

### ⚠️ Recursos Aún Activos (Mínimo)
- **EKS Control Plane:** ~$73/mes
- **NAT Gateways (2):** ~$65/mes
- **EBS Volumes:** ~$16/mes
- **Total mientras está pausado:** ~$154/mes

---

## ⏸️ PAUSAR Recursos (Ya Ejecutado)

```powershell
# 1. Escalar nodos a 0
aws eks update-nodegroup-config `
  --cluster-name ecom-staging-eks `
  --nodegroup-name ecom-staging-node-group `
  --scaling-config minSize=0,maxSize=4,desiredSize=0 `
  --region us-east-1

# 2. Eliminar LoadBalancers
kubectl delete svc api-gateway-external grafana-external zipkin-external -n microservices-staging

# 3. Verificar estado
aws eks describe-nodegroup --cluster-name ecom-staging-eks --nodegroup-name ecom-staging-node-group --region us-east-1
```

**Ahorro:** ~$110/mes (EC2 + LoadBalancers)

---

## ▶️ REACTIVAR Recursos

### Paso 1: Reactivar Nodos EC2

```powershell
# Escalar de vuelta a 2 nodos
aws eks update-nodegroup-config `
  --cluster-name ecom-staging-eks `
  --nodegroup-name ecom-staging-node-group `
  --scaling-config minSize=1,maxSize=4,desiredSize=2 `
  --region us-east-1

# Esperar a que los nodos estén listos (5-10 minutos)
kubectl get nodes --watch
```

### Paso 2: Verificar que los Pods Arranquen

```powershell
# Los pods deberían arrancar automáticamente cuando los nodos estén Ready
kubectl get pods -n microservices-staging

# Si no arrancan, recrear deployments
kubectl rollout restart deployment -n microservices-staging --all
```

### Paso 3: Recrear LoadBalancers

```powershell
# API Gateway External
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: api-gateway-external
  namespace: microservices-staging
spec:
  type: LoadBalancer
  selector:
    app: api-gateway
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
EOF

# Grafana External
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: grafana-external
  namespace: microservices-staging
spec:
  type: LoadBalancer
  selector:
    app: grafana
  ports:
    - port: 80
      targetPort: 3000
      protocol: TCP
EOF

# Zipkin External
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: zipkin-external
  namespace: microservices-staging
spec:
  type: LoadBalancer
  selector:
    app: zipkin
  ports:
    - port: 80
      targetPort: 9411
      protocol: TCP
EOF
```

### Paso 4: Obtener Nuevas URLs

```powershell
# Esperar a que AWS provisione los LoadBalancers (2-3 minutos)
Start-Sleep -Seconds 120

# Obtener nuevas URLs
kubectl get svc -n microservices-staging | Select-String "LoadBalancer"

# O específicamente:
kubectl get svc api-gateway-external -n microservices-staging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
kubectl get svc grafana-external -n microservices-staging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
kubectl get svc zipkin-external -n microservices-staging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Paso 5: Probar que Todo Funcione

```powershell
# Health check (reemplaza con tu nueva URL)
$API_URL = "http://[NUEVA-URL-LOADBALANCER]"
curl "$API_URL/actuator/health"

# Productos
curl "$API_URL/product-service/api/products"

# Users
curl "$API_URL/user-service/api/users"
```

---

## 🔧 Script Completo de Reactivación

Guarda esto como `reactivar-aws.ps1`:

```powershell
#!/usr/bin/env pwsh
# reactivar-aws.ps1 - Reactivar infraestructura AWS pausada

Write-Host "🚀 Reactivando infraestructura AWS..." -ForegroundColor Green

# 1. Reactivar nodos
Write-Host "`n1️⃣ Escalando nodos a 2..." -ForegroundColor Cyan
aws eks update-nodegroup-config `
  --cluster-name ecom-staging-eks `
  --nodegroup-name ecom-staging-node-group `
  --scaling-config minSize=1,maxSize=4,desiredSize=2 `
  --region us-east-1

Write-Host "   ⏳ Esperando 5 minutos para que los nodos estén Ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 300

# 2. Verificar nodos
Write-Host "`n2️⃣ Verificando nodos..." -ForegroundColor Cyan
kubectl get nodes

# 3. Verificar pods
Write-Host "`n3️⃣ Verificando pods..." -ForegroundColor Cyan
kubectl get pods -n microservices-staging

# 4. Recrear LoadBalancers
Write-Host "`n4️⃣ Recreando LoadBalancers..." -ForegroundColor Cyan

# API Gateway
@"
apiVersion: v1
kind: Service
metadata:
  name: api-gateway-external
  namespace: microservices-staging
spec:
  type: LoadBalancer
  selector:
    app: api-gateway
  ports:
    - port: 80
      targetPort: 8080
"@ | kubectl apply -f -

# Grafana
@"
apiVersion: v1
kind: Service
metadata:
  name: grafana-external
  namespace: microservices-staging
spec:
  type: LoadBalancer
  selector:
    app: grafana
  ports:
    - port: 80
      targetPort: 3000
"@ | kubectl apply -f -

# Zipkin
@"
apiVersion: v1
kind: Service
metadata:
  name: zipkin-external
  namespace: microservices-staging
spec:
  type: LoadBalancer
  selector:
    app: zipkin
  ports:
    - port: 80
      targetPort: 9411
"@ | kubectl apply -f -

Write-Host "   ⏳ Esperando 2 minutos para LoadBalancers..." -ForegroundColor Yellow
Start-Sleep -Seconds 120

# 5. Obtener URLs
Write-Host "`n5️⃣ Nuevas URLs:" -ForegroundColor Cyan
Write-Host "`nAPI Gateway:" -ForegroundColor Yellow
kubectl get svc api-gateway-external -n microservices-staging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

Write-Host "`n`nGrafana:" -ForegroundColor Yellow
kubectl get svc grafana-external -n microservices-staging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

Write-Host "`n`nZipkin:" -ForegroundColor Yellow
kubectl get svc zipkin-external -n microservices-staging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

Write-Host "`n`n✅ Infraestructura reactivada!" -ForegroundColor Green
Write-Host "⚠️ Guarda las nuevas URLs en DEPLOYMENT_INFO.md" -ForegroundColor Yellow
```

---

## 📊 Verificar Estado Actual

```powershell
# Ver estado de nodos
aws eks describe-nodegroup --cluster-name ecom-staging-eks --nodegroup-name ecom-staging-node-group --region us-east-1 --query 'nodegroup.scalingConfig'

# Ver LoadBalancers activos
aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[].LoadBalancerName'

# Ver estado del cluster
kubectl cluster-info
kubectl get nodes
kubectl get pods -n microservices-staging
```

---

## ⚠️ Notas Importantes

### Mientras está Pausado
- ✅ No pagas por EC2 (~$60/mes ahorrado)
- ✅ No pagas por LoadBalancers (~$50/mes ahorrado)
- ⚠️ Sigues pagando EKS Control Plane (~$73/mes)
- ⚠️ Sigues pagando NAT Gateways (~$65/mes)
- ⚠️ Sigues pagando EBS Volumes (~$16/mes)

### Al Reactivar
- Las **URLs de LoadBalancer cambiarán** (nuevas direcciones)
- Los **pods arrancarán automáticamente** (gracias a los Deployments)
- Las **imágenes Docker** se descargan de Docker Hub (alejomunoz/*)
- El **ConfigMap** mantiene toda la configuración
- Toma **~10 minutos** en estar completamente operativo

### Para Ahorrar Más
Si quieres ahorrar los **$154/mes** restantes, debes destruir completamente con:
```powershell
cd infra/terraform/environments/staging
terraform destroy
```
⚠️ Pero tendrás que recrear todo con `terraform apply` (~20 minutos)

---

## 💡 Recomendación

**Opción Actual (Pausado):** ~$154/mes
- Reactivación rápida (10 minutos)
- Solo recreas LoadBalancers
- URLs cambian

**Opción Destruir Todo:** $0/mes
- Recreación completa (20 minutos)
- Ejecutar `terraform apply`
- Todo desde cero

Para uso esporádico, **mantener pausado es mejor**.
