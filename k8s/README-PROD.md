# Despliegue a Kubernetes (Producción)

Este directorio contiene los manifiestos de Kubernetes y scripts para desplegar el sistema de e-commerce a producción usando **Amazon EKS**.

## 📁 Estructura

```
k8s/
├── base/                           # Manifiestos base para todos los servicios
│   ├── api-gateway.yaml
│   ├── product-service.yaml
│   ├── user-service.yaml
│   ├── order-service.yaml
│   ├── payment-service.yaml
│   ├── shipping-service.yaml
│   ├── favourite-service.yaml
│   ├── proxy-client.yaml
│   ├── service-discovery.yaml
│   ├── cloud-config.yaml
│   ├── zipkin.yaml
│   ├── prometheus.yaml
│   ├── grafana.yaml
│   └── namespaces.yaml
│
├── production/                     # Configuración específica de producción
│   ├── configmap.yaml             # Variables de entorno
│   ├── internal-services.yaml     # Servicios internos (cloud-config, zipkin)
│   ├── prometheus-config.yaml     # Config de Prometheus
│   └── prometheus-scrape-config.yaml
│
├── staging/                        # Configuración de staging
│   └── configmap.yaml
│
├── deploy-k8s-prod.sh             # Script Bash para despliegue
└── deploy-k8s-prod.ps1            # Script PowerShell para despliegue
```

## 🚀 Pipeline de CI/CD

### Workflow: `deploy-prod-k8s.yml`

El pipeline se activa:
- **Automáticamente**: Al hacer push a la rama `master`
- **Manualmente**: Desde GitHub Actions con `workflow_dispatch`

### Flujo del Pipeline

```mermaid
graph TD
    A[Push a master] --> B[Buscar último release stage-*]
    B --> C[Desplegar servicios de aplicación]
    C --> D[Esperar estabilidad de deployments]
    D --> E[Ejecutar Smoke Tests]
    E --> F[Generar Release de Producción]
    F --> G[Post-Deployment Verification]
    
    H[Manual: run_infra=true] --> I[Desplegar servicios de infraestructura]
    I --> J[service-discovery + cloud-config]
```

### Jobs del Pipeline

#### 1. **fetch-stage-tag**
- Busca el último release que comience con `stage-`
- Extrae la versión (ej: `stage-1.2.3` → `1.2.3`)
- Usa esa versión para las imágenes de producción

#### 2. **kubernetes-deploy** (Automático)
Despliega **solo servicios de aplicación**:
- ✅ api-gateway
- ✅ product-service
- ✅ user-service
- ✅ order-service
- ✅ payment-service
- ✅ shipping-service
- ✅ favourite-service
- ✅ proxy-client

**Excluye servicios de infraestructura** (requieren aprobación manual)

#### 3. **kubernetes-deploy-infra** (Manual)
Despliega **servicios de infraestructura** con aprobación:
- 🔧 service-discovery (Eureka)
- 🔧 cloud-config

Se ejecuta **solo con `workflow_dispatch`** y `run_infra=true`

#### 4. **smoke-tests**
Ejecuta pruebas básicas de salud:
- Verifica endpoints de todos los servicios
- Timeout: 15 minutos
- Genera reporte de resultados

#### 5. **generate-release-notes**
- Crea un GitHub Release con tag `v{version}`
- Copia el changelog del release de staging
- Lista todas las imágenes desplegadas

#### 6. **post-deployment**
- Muestra el estado final de todos los recursos
- Lista deployments, pods y servicios

## 🛠️ Configuración Inicial

### 1. Crear Cluster EKS

Puedes usar Terraform o AWS CLI:

```bash
# Opción 1: Con Terraform
cd infra/modules/eks
terraform init
terraform plan
terraform apply

# Opción 2: Con AWS CLI
aws eks create-cluster \
  --name prod-ecommerce-cluster \
  --region us-east-1 \
  --kubernetes-version 1.28 \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/eks-cluster-role \
  --resources-vpc-config subnetIds=subnet-xxx,subnet-yyy,securityGroupIds=sg-xxx
```

### 2. Configurar kubeconfig

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name prod-ecommerce-cluster
```

### 3. Configurar Secrets en GitHub

Ve a: `Settings → Secrets and variables → Actions → New repository secret`

| Secret | Descripción | Ejemplo |
|--------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | Access Key de AWS | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Secret Key de AWS | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | Región de AWS | `us-east-1` |

### 4. Configurar Environments

Crea estos environments en GitHub con protección:

#### Environment: `production`
- **Configuración**: `Settings → Environments → New environment`
- **Nombre**: `production`
- **Protection rules**:
  - ✅ Required reviewers (2 personas)
  - ✅ Wait timer: 5 minutos
  - ✅ Deployment branches: `master` only

#### Environment: `production-infra`
- **Nombre**: `production-infra`
- **Protection rules**:
  - ✅ Required reviewers (3 personas - equipo senior)
  - ✅ Wait timer: 10 minutos
  - ⚠️ **CRÍTICO**: Solo para cambios de infraestructura

## 📦 Despliegue Manual

Si necesitas desplegar manualmente (sin CI/CD):

### Usando PowerShell (Windows)

```powershell
# Configurar kubeconfig primero
aws eks update-kubeconfig --region us-east-1 --name prod-ecommerce-cluster

# Desplegar con versión específica
.\k8s\deploy-k8s-prod.ps1 -ImageTag "v1.2.3"

# O usar latest
.\k8s\deploy-k8s-prod.ps1
```

### Usando Bash (Linux/Mac)

```bash
# Configurar kubeconfig
aws eks update-kubeconfig --region us-east-1 --name prod-ecommerce-cluster

# Dar permisos de ejecución
chmod +x k8s/deploy-k8s-prod.sh

# Desplegar
./k8s/deploy-k8s-prod.sh v1.2.3
```

## 🔍 Verificación del Despliegue

### Ver estado de los pods

```bash
kubectl get pods -n microservices-prod -o wide
```

### Ver logs de un servicio

```bash
# Logs en tiempo real
kubectl logs -f -l app=api-gateway -n microservices-prod

# Últimas 100 líneas
kubectl logs -l app=product-service -n microservices-prod --tail=100
```

### Verificar health de servicios

```bash
# Obtener el endpoint del API Gateway
GATEWAY_HOST=$(kubectl get svc api-gateway -n microservices-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Verificar health
curl http://$GATEWAY_HOST/actuator/health

# Verificar un servicio específico
curl http://$GATEWAY_HOST/product-service/api/products
```

### Ver estado de deployments

```bash
kubectl get deployments -n microservices-prod
```

### Ejecutar un rollback

```bash
# Ver historial de revisiones
kubectl rollout history deployment/api-gateway -n microservices-prod

# Rollback a la revisión anterior
kubectl rollout undo deployment/api-gateway -n microservices-prod

# Rollback a revisión específica
kubectl rollout undo deployment/api-gateway -n microservices-prod --to-revision=2
```

## 🔄 Flujo de Trabajo Típico

### 1. Despliegue Normal (Aplicaciones)

```bash
# En tu máquina local
git checkout develop
git pull origin develop

# Hacer cambios y commit
git add .
git commit -m "feat: nueva funcionalidad"
git push origin develop

# Crear PR a master
# Después de aprobación, hacer merge

git checkout master
git pull origin master

# El pipeline se ejecuta automáticamente:
# ✅ Busca último stage release
# ✅ Despliega servicios de aplicación
# ✅ Ejecuta smoke tests
# ✅ Crea release de producción
```

### 2. Actualización de Infraestructura (Manual)

```bash
# 1. Ir a GitHub Actions
# 2. Seleccionar: deploy-prod-k8s.yml
# 3. Click en "Run workflow"
# 4. Configurar:
#    - Branch: master
#    - run_infra: true
# 5. Click "Run workflow"
# 6. Esperar aprobación de reviewers
# 7. Deployment se ejecuta después de aprobación
```

## 📊 Monitoreo

### Prometheus + Grafana

Los manifiestos incluyen configuración para Prometheus y Grafana:

```bash
# Aplicar configuración de Prometheus
kubectl apply -f k8s/production/prometheus-config.yaml
kubectl apply -f k8s/production/prometheus-scrape-config.yaml

# Aplicar Prometheus
kubectl apply -f k8s/base/prometheus.yaml

# Aplicar Grafana
kubectl apply -f k8s/base/grafana.yaml

# Port forward para acceder localmente
kubectl port-forward svc/prometheus -n microservices-prod 9090:9090
kubectl port-forward svc/grafana -n microservices-prod 3000:3000
```

### Logs Centralizados

Si usas CloudWatch Container Insights:

```bash
# Instalar Fluent Bit
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml

# Ver logs en CloudWatch
aws logs tail /aws/containerinsights/prod-ecommerce-cluster/application --follow
```

## 🚨 Troubleshooting

### Pods en estado CrashLoopBackOff

```bash
# Ver detalles del pod
kubectl describe pod <pod-name> -n microservices-prod

# Ver logs del pod fallido
kubectl logs <pod-name> -n microservices-prod --previous
```

### Servicio no responde

```bash
# Verificar endpoints
kubectl get endpoints -n microservices-prod

# Verificar si el pod está listo
kubectl get pods -n microservices-prod

# Test de conectividad desde otro pod
kubectl run test-pod --rm -it --image=curlimages/curl -n microservices-prod -- sh
curl http://product-service:8500/product-service/actuator/health
```

### Imagen no se puede descargar

```bash
# Verificar image pull secrets
kubectl get secrets -n microservices-prod

# Crear secret para GHCR si es necesario
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=lolito996 \
  --docker-password=<GITHUB_TOKEN> \
  --namespace=microservices-prod

# Asociar secret a service account
kubectl patch serviceaccount default \
  -n microservices-prod \
  -p '{"imagePullSecrets": [{"name": "ghcr-secret"}]}'
```

### Deployment atascado

```bash
# Ver eventos
kubectl get events -n microservices-prod --sort-by='.lastTimestamp'

# Forzar recreación de pods
kubectl rollout restart deployment/api-gateway -n microservices-prod

# Eliminar pods problemáticos
kubectl delete pod <pod-name> -n microservices-prod
```

## 🔒 Seguridad

### Network Policies

Considera implementar network policies para restringir tráfico:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-api-gateway
  namespace: microservices-prod
spec:
  podSelector:
    matchLabels:
      app: product-service
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-gateway
```

### Pod Security Standards

```bash
# Aplicar pod security al namespace
kubectl label namespace microservices-prod \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

## 📚 Referencias

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Amazon EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [GitHub Actions - Kubernetes](https://github.com/marketplace/actions/kubernetes-cli-kubectl)
