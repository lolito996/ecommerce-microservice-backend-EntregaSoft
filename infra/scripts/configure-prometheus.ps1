# Script para configurar Prometheus con archivo de configuración personalizado
# Uso: .\configure-prometheus.ps1

$ErrorActionPreference = "Stop"

$REGION = "us-east-1"
$CLUSTER = "dev-ecommerce-cluster"

Write-Host "🔧 Configurando Prometheus para ECS..." -ForegroundColor Cyan

# 1. Crear el archivo de configuración de Prometheus adaptado para ECS
Write-Host "`n📝 Creando configuración de Prometheus..." -ForegroundColor Yellow

# Obtener IPs privadas de todos los servicios
Write-Host "📍 Obteniendo IPs de los microservicios..." -ForegroundColor Gray

$services = @(
    "dev-api-gateway",
    "dev-user-service", 
    "dev-product-service",
    "dev-order-service",
    "dev-payment-service",
    "dev-shipping-service",
    "dev-favourite-service",
    "dev-service-discovery",
    "dev-cloud-config",
    "dev-proxy-client"
)

$serviceIps = @{}

foreach ($service in $services) {
    $taskArn = aws ecs list-tasks `
        --cluster $CLUSTER `
        --service-name $service `
        --region $REGION `
        --query 'taskArns[0]' `
        --output text
    
    if ($taskArn -and $taskArn -ne "None") {
        $ip = aws ecs describe-tasks `
            --cluster $CLUSTER `
            --tasks $taskArn `
            --region $REGION `
            --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' `
            --output text
        
        if ($ip) {
            $serviceIps[$service] = $ip
            Write-Host "  ✓ $service : $ip" -ForegroundColor Green
        }
    }
}

# 2. Crear configuración de Prometheus con IPs reales
$prometheusConfig = @"
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'microservices-ecs'
    environment: 'dev'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

"@

# Agregar cada servicio a la configuración
if ($serviceIps["dev-api-gateway"]) {
    $prometheusConfig += @"

  - job_name: 'api-gateway'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$($serviceIps["dev-api-gateway"]):8080']

"@
}

if ($serviceIps["dev-user-service"]) {
    $prometheusConfig += @"
  - job_name: 'user-service'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$($serviceIps["dev-user-service"]):8081']

"@
}

if ($serviceIps["dev-product-service"]) {
    $prometheusConfig += @"
  - job_name: 'product-service'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$($serviceIps["dev-product-service"]):8082']

"@
}

if ($serviceIps["dev-order-service"]) {
    $prometheusConfig += @"
  - job_name: 'order-service'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$($serviceIps["dev-order-service"]):8083']

"@
}

if ($serviceIps["dev-payment-service"]) {
    $prometheusConfig += @"
  - job_name: 'payment-service'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$($serviceIps["dev-payment-service"]):8084']

"@
}

if ($serviceIps["dev-shipping-service"]) {
    $prometheusConfig += @"
  - job_name: 'shipping-service'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$($serviceIps["dev-shipping-service"]):8085']

"@
}

if ($serviceIps["dev-favourite-service"]) {
    $prometheusConfig += @"
  - job_name: 'favourite-service'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$($serviceIps["dev-favourite-service"]):8086']

"@
}

if ($serviceIps["dev-service-discovery"]) {
    $prometheusConfig += @"
  - job_name: 'service-discovery'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$($serviceIps["dev-service-discovery"]):8761']

"@
}

if ($serviceIps["dev-cloud-config"]) {
    $prometheusConfig += @"
  - job_name: 'cloud-config'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$($serviceIps["dev-cloud-config"]):8888']

"@
}

if ($serviceIps["dev-proxy-client"]) {
    $prometheusConfig += @"
  - job_name: 'proxy-client'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$($serviceIps["dev-proxy-client"]):8087']

"@
}

# Guardar configuración temporalmente
$prometheusConfig | Out-File -FilePath "prometheus-ecs-config.yml" -Encoding utf8
Write-Host "✅ Configuración creada" -ForegroundColor Green

# 3. Guardar en SSM Parameter Store
Write-Host "`n📦 Guardando configuración en AWS SSM Parameter Store..." -ForegroundColor Yellow

aws ssm put-parameter `
    --name "/ecs/dev/prometheus/config" `
    --value $prometheusConfig `
    --type "String" `
    --overwrite `
    --region $REGION | Out-Null

Write-Host "✅ Configuración guardada en SSM" -ForegroundColor Green

# 4. Crear un script de inicio que descargue la configuración
Write-Host "`n⚠️  NOTA IMPORTANTE:" -ForegroundColor Yellow
Write-Host "Para que Prometheus use esta configuración, necesitas:" -ForegroundColor White
Write-Host "1. Usar AWS Secrets/Config para inyectar la configuración al contenedor" -ForegroundColor Gray
Write-Host "2. O mejor aún, crear una imagen Docker personalizada con la configuración" -ForegroundColor Gray

Write-Host "`n📋 Configuración generada guardada en: prometheus-ecs-config.yml" -ForegroundColor Cyan
Write-Host "`n🔍 Para verificar si los microservicios exponen métricas:" -ForegroundColor Yellow
Write-Host "curl http://<ip-del-servicio>:8080/actuator/prometheus" -ForegroundColor White

Write-Host "`n💡 Solución recomendada: Crear imagen Docker personalizada" -ForegroundColor Cyan
Write-Host "   Esto se puede hacer con un Dockerfile que incluya tu configuración" -ForegroundColor Gray
