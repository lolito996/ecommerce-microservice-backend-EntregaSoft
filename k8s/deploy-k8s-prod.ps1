# Script PowerShell para desplegar a Kubernetes (producción)
# Uso: .\deploy-k8s-prod.ps1 [-ImageTag "v1.0.0"]

param(
    [string]$ImageTag = "latest"
)

# Configuración
$NAMESPACE = "microservices-prod"
$REGISTRY = "ghcr.io/lolito996"
$NODE_PORT = "30080"

Write-Host "🚀 Desplegando a Kubernetes - Producción" -ForegroundColor Cyan
Write-Host "📦 Registry: $REGISTRY" -ForegroundColor White
Write-Host "🏷️  Image Tag: $ImageTag" -ForegroundColor White
Write-Host "📍 Namespace: $NAMESPACE" -ForegroundColor White
Write-Host ""

# Función para aplicar manifiestos
function Apply-Manifest {
    param(
        [string]$FilePath
    )
    
    $serviceName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    Write-Host "📦 Aplicando: $serviceName" -ForegroundColor Yellow
    
    try {
        # Leer el archivo y reemplazar variables
        $content = Get-Content $FilePath -Raw
        $content = $content -replace '\$\{NAMESPACE\}', $NAMESPACE
        $content = $content -replace '\$\{REGISTRY\}', $REGISTRY
        $content = $content -replace '\$\{IMAGE_TAG\}', $ImageTag
        $content = $content -replace '\$\{NODE_PORT\}', $NODE_PORT
        
        # Aplicar mediante pipeline
        $content | kubectl apply -f -
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $serviceName aplicado" -ForegroundColor Green
        } else {
            Write-Host "❌ Error aplicando $serviceName" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error procesando $serviceName : $_" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
    return $true
}

# Verificar conexión al cluster
Write-Host "🔍 Verificando conexión al cluster..." -ForegroundColor Cyan
try {
    kubectl cluster-info | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "No se puede conectar al cluster"
    }
    Write-Host "✅ Conectado al cluster" -ForegroundColor Green
}
catch {
    Write-Host "❌ No se puede conectar al cluster de Kubernetes" -ForegroundColor Red
    Write-Host "Ejecuta: aws eks update-kubeconfig --region us-east-1 --name prod-ecommerce-cluster" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Crear namespace
Write-Host "📁 Creando namespace..." -ForegroundColor Cyan
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
Write-Host ""

# Aplicar ConfigMap
Write-Host "⚙️  Aplicando ConfigMap..." -ForegroundColor Cyan
kubectl apply -f k8s/production/configmap.yaml
Write-Host ""

# Aplicar servicios internos
Write-Host "🔧 Aplicando servicios internos..." -ForegroundColor Cyan
kubectl apply -f k8s/production/internal-services.yaml
Write-Host ""

# Servicios de infraestructura
Write-Host "🏗️  Desplegando servicios de infraestructura..." -ForegroundColor Cyan
$infraServices = @(
    "k8s/base/service-discovery.yaml",
    "k8s/base/cloud-config.yaml",
    "k8s/base/zipkin.yaml"
)

foreach ($service in $infraServices) {
    if (Test-Path $service) {
        Apply-Manifest -FilePath $service
    } else {
        Write-Host "⚠️  Archivo no encontrado: $service" -ForegroundColor Yellow
    }
}

Write-Host "⏳ Esperando 60 segundos para que los servicios de infraestructura estén listos..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Servicios de aplicación
Write-Host "📦 Desplegando servicios de aplicación..." -ForegroundColor Cyan
$appServices = @(
    "k8s/base/api-gateway.yaml",
    "k8s/base/user-service.yaml",
    "k8s/base/product-service.yaml",
    "k8s/base/order-service.yaml",
    "k8s/base/payment-service.yaml",
    "k8s/base/shipping-service.yaml",
    "k8s/base/favourite-service.yaml",
    "k8s/base/proxy-client.yaml"
)

foreach ($service in $appServices) {
    if (Test-Path $service) {
        Apply-Manifest -FilePath $service
    } else {
        Write-Host "⚠️  Archivo no encontrado: $service" -ForegroundColor Yellow
    }
}

# Aplicar Prometheus (si existe)
if (Test-Path "k8s/production/prometheus-config.yaml") {
    Write-Host "📊 Aplicando configuración de Prometheus..." -ForegroundColor Cyan
    kubectl apply -f k8s/production/prometheus-config.yaml
}

# Mostrar estado
Write-Host ""
Write-Host "📊 Estado de los deployments:" -ForegroundColor Cyan
kubectl get deployments -n $NAMESPACE -o wide

Write-Host ""
Write-Host "📋 Estado de los pods:" -ForegroundColor Cyan
kubectl get pods -n $NAMESPACE -o wide

Write-Host ""
Write-Host "🌐 Servicios expuestos:" -ForegroundColor Cyan
kubectl get svc -n $NAMESPACE -o wide

Write-Host ""
Write-Host "✅ Despliegue completado" -ForegroundColor Green
Write-Host ""
Write-Host "Para ver logs de un servicio:" -ForegroundColor Yellow
Write-Host "  kubectl logs -f -l app=<service-name> -n $NAMESPACE" -ForegroundColor White
Write-Host ""
Write-Host "Para verificar el estado:" -ForegroundColor Yellow
Write-Host "  kubectl rollout status deployment/<service-name> -n $NAMESPACE" -ForegroundColor White
