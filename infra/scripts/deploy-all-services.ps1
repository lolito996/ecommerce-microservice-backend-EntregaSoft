# Script para desplegar TODOS los servicios cuando el rate limit se resetee
# Uso: .\deploy-all-services.ps1

$ErrorActionPreference = "Stop"

$CLUSTER = "dev-ecommerce-cluster"
$REGION = "us-east-1"

Write-Host "🚀 Desplegando TODOS los servicios..." -ForegroundColor Cyan

# 1. Verificar rate limit de Docker Hub
Write-Host "`n📊 Verificando rate limit de Docker Hub..." -ForegroundColor Yellow
try {
    $rateLimitResponse = curl -s -I "https://registry-1.docker.io/v2/" 2>&1
    Write-Host "Verificación completada" -ForegroundColor Green
} catch {
    Write-Host "⚠️  No se pudo verificar el rate limit" -ForegroundColor Yellow
}

# 2. Escalar servicios fallidos a 1
Write-Host "`n📈 Escalando servicios a 1..." -ForegroundColor Yellow

$failedServices = @(
    "dev-product-service",
    "dev-order-service",
    "dev-payment-service",
    "dev-shipping-service",
    "dev-favourite-service"
)

foreach ($service in $failedServices) {
    Write-Host "  Escalando $service..." -ForegroundColor Gray
    aws ecs update-service `
        --cluster $CLUSTER `
        --service $service `
        --desired-count 1 `
        --region $REGION `
        --query 'service.[serviceName,desiredCount]' `
        --output text | Out-Null
    Write-Host "  ✅ $service escalado a 1" -ForegroundColor Green
}

# 3. Esperar a que los servicios inicien (3 minutos)
Write-Host "`n⏳ Esperando a que los servicios inicien (esto puede tardar 3-4 minutos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 180

# 4. Verificar estado de todos los servicios
Write-Host "`n📊 Verificando estado de servicios..." -ForegroundColor Yellow

$allServices = @(
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

$runningCount = 0
$failedCount = 0

foreach ($service in $allServices) {
    $status = aws ecs describe-services `
        --cluster $CLUSTER `
        --services $service `
        --region $REGION `
        --query 'services[0].[runningCount,desiredCount]' `
        --output text 2>$null
    
    if ($status) {
        $parts = $status -split '\s+'
        if ($parts[0] -eq $parts[1] -and $parts[0] -eq "1") {
            Write-Host "  ✅ $service : $($parts[0])/$($parts[1])" -ForegroundColor Green
            $runningCount++
        } else {
            Write-Host "  ❌ $service : $($parts[0])/$($parts[1])" -ForegroundColor Red
            $failedCount++
        }
    }
}

Write-Host "`n📊 Resumen: $runningCount corriendo, $failedCount fallidos" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    Write-Host "`n⚠️  Algunos servicios fallaron. Verifica los eventos:" -ForegroundColor Yellow
    Write-Host "aws ecs describe-services --cluster $CLUSTER --services <nombre-servicio> --region $REGION --query 'services[0].events[0].message'" -ForegroundColor Gray
    
    $response = Read-Host "`n¿Deseas continuar con Prometheus de todas formas? (s/n)"
    if ($response -ne "s") {
        Write-Host "❌ Proceso cancelado" -ForegroundColor Red
        exit 1
    }
}

# 5. Regenerar configuración de Prometheus con TODAS las IPs
Write-Host "`n🔧 Regenerando configuración de Prometheus..." -ForegroundColor Yellow

$runningServices = @{
    "dev-api-gateway" = @{ port = 8080; path = "/actuator/prometheus" }
    "dev-user-service" = @{ port = 8081; path = "/actuator/prometheus" }
    "dev-product-service" = @{ port = 8082; path = "/actuator/prometheus" }
    "dev-order-service" = @{ port = 8083; path = "/actuator/prometheus" }
    "dev-payment-service" = @{ port = 8084; path = "/actuator/prometheus" }
    "dev-shipping-service" = @{ port = 8085; path = "/actuator/prometheus" }
    "dev-favourite-service" = @{ port = 8086; path = "/actuator/prometheus" }
    "dev-service-discovery" = @{ port = 8761; path = "/actuator/prometheus" }
    "dev-cloud-config" = @{ port = 8888; path = "/actuator/prometheus" }
    "dev-proxy-client" = @{ port = 8087; path = "/actuator/prometheus" }
}

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

$targetsFound = 0

foreach ($serviceName in $runningServices.Keys) {
    $taskArn = aws ecs list-tasks `
        --cluster $CLUSTER `
        --service-name $serviceName `
        --region $REGION `
        --query 'taskArns[0]' `
        --output text 2>$null
    
    if ($taskArn -and $taskArn -ne "None" -and $taskArn -ne "") {
        $ip = aws ecs describe-tasks `
            --cluster $CLUSTER `
            --tasks $taskArn `
            --region $REGION `
            --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' `
            --output text 2>$null
        
        if ($ip) {
            $serviceInfo = $runningServices[$serviceName]
            $jobName = $serviceName -replace '^dev-', ''
            
            $prometheusConfig += @"

  - job_name: '$jobName'
    metrics_path: '$($serviceInfo.path)'
    static_configs:
      - targets: ['${ip}:$($serviceInfo.port)']
        labels:
          service: '$jobName'
          environment: 'dev'
"@
            Write-Host "  ✓ $jobName : ${ip}:$($serviceInfo.port)" -ForegroundColor Green
            $targetsFound++
        }
    }
}

Write-Host "`n📊 Total de targets configurados: $targetsFound" -ForegroundColor Cyan

# Guardar configuración
$prometheusConfig | Out-File -FilePath "prometheus-complete.yml" -Encoding utf8
Write-Host "✅ Configuración guardada en: prometheus-complete.yml" -ForegroundColor Green

# 6. Construir y subir imagen de Prometheus
Write-Host "`n🐳 Construyendo imagen de Prometheus..." -ForegroundColor Yellow

Copy-Item "prometheus-complete.yml" "..\..\monitoring\prometheus\prometheus.yml" -Force

Set-Location "..\..\monitoring\prometheus"

Write-Host "  Construyendo imagen..." -ForegroundColor Gray
docker build -t alejomunoz/prometheus-ecommerce:latest . | Out-Null

Write-Host "  Subiendo a Docker Hub..." -ForegroundColor Gray
docker push alejomunoz/prometheus-ecommerce:latest | Out-Null

Write-Host "✅ Imagen actualizada y subida" -ForegroundColor Green

Set-Location "..\..\infra\scripts"

# 7. Forzar redespliegue de Prometheus
Write-Host "`n🔄 Redesplegando Prometheus..." -ForegroundColor Yellow

aws ecs update-service `
    --cluster $CLUSTER `
    --service dev-prometheus `
    --force-new-deployment `
    --region $REGION `
    --query 'service.[serviceName,desiredCount]' `
    --output text | Out-Null

Write-Host "✅ Prometheus redesplegado" -ForegroundColor Green

# 8. Esperar despliegue
Write-Host "`n⏳ Esperando a que Prometheus se redespliegue (2 minutos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 120

# 9. Actualizar target group de Prometheus
Write-Host "`n🔗 Actualizando target group de Prometheus..." -ForegroundColor Yellow

$prometheusTaskArn = aws ecs list-tasks `
    --cluster $CLUSTER `
    --service-name dev-prometheus `
    --region $REGION `
    --query 'taskArns[0]' `
    --output text

if ($prometheusTaskArn -and $prometheusTaskArn -ne "None") {
    $prometheusIp = aws ecs describe-tasks `
        --cluster $CLUSTER `
        --tasks $prometheusTaskArn `
        --region $REGION `
        --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' `
        --output text
    
    Write-Host "  IP de Prometheus: $prometheusIp" -ForegroundColor Cyan
    
    # Desregistrar IPs antiguas
    $oldTargets = aws elbv2 describe-target-health `
        --target-group-arn arn:aws:elasticloadbalancing:us-east-1:533924338325:targetgroup/dev-prometheus-tg/c40eee6fc650cbf2 `
        --region $REGION `
        --query 'TargetHealthDescriptions[*].Target.Id' `
        --output text
    
    if ($oldTargets) {
        foreach ($oldIp in $oldTargets -split '\s+') {
            if ($oldIp -and $oldIp -ne $prometheusIp) {
                aws elbv2 deregister-targets `
                    --target-group-arn arn:aws:elasticloadbalancing:us-east-1:533924338325:targetgroup/dev-prometheus-tg/c40eee6fc650cbf2 `
                    --targets Id=$oldIp,Port=9090 `
                    --region $REGION 2>$null
            }
        }
    }
    
    # Registrar nueva IP
    aws elbv2 register-targets `
        --target-group-arn arn:aws:elasticloadbalancing:us-east-1:533924338325:targetgroup/dev-prometheus-tg/c40eee6fc650cbf2 `
        --targets Id=$prometheusIp,Port=9090 `
        --region $REGION 2>$null
    
    Write-Host "✅ Target group actualizado" -ForegroundColor Green
    
    # Esperar health check
    Write-Host "`n⏳ Esperando health check (30 segundos)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    $health = aws elbv2 describe-target-health `
        --target-group-arn arn:aws:elasticloadbalancing:us-east-1:533924338325:targetgroup/dev-prometheus-tg/c40eee6fc650cbf2 `
        --region $REGION `
        --query "TargetHealthDescriptions[?Target.Id=='$prometheusIp'].TargetHealth.State" `
        --output text
    
    if ($health -eq "healthy") {
        Write-Host "✅ Prometheus está HEALTHY" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Prometheus health: $health (espera unos minutos más)" -ForegroundColor Yellow
    }
}

# 10. Actualizar datasource en Grafana
Write-Host "`n🔧 Actualizando datasource de Grafana..." -ForegroundColor Yellow

if ($prometheusIp) {
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:admin123"))
    $headers = @{
        Authorization = "Basic $base64Auth"
        "Content-Type" = "application/json"
    }
    
    $datasource = @{
        id = 1
        uid = "fc50ebb7-d4d1-465d-b3b8-e962cb89e128"
        orgId = 1
        name = "Prometheus"
        type = "prometheus"
        access = "proxy"
        url = "http://${prometheusIp}:9090"
        isDefault = $true
        jsonData = @{
            timeInterval = "15s"
            httpMethod = "POST"
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod `
            -Uri "http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com:3000/api/datasources/1" `
            -Method Put `
            -Headers $headers `
            -Body $datasource
        
        Write-Host "✅ Datasource de Grafana actualizado" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Error al actualizar Grafana: $_" -ForegroundColor Yellow
    }
}

# 11. Verificar targets en Prometheus
Write-Host "`n📊 Verificando targets en Prometheus..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

try {
    $targets = curl -s "http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com:9090/api/v1/targets" | ConvertFrom-Json
    $activeTargets = $targets.data.activeTargets
    
    $upCount = ($activeTargets | Where-Object { $_.health -eq "up" }).Count
    $downCount = ($activeTargets | Where-Object { $_.health -eq "down" }).Count
    
    Write-Host "`n✅ Targets UP: $upCount" -ForegroundColor Green
    Write-Host "❌ Targets DOWN: $downCount" -ForegroundColor Red
    
    Write-Host "`n📋 Detalle de targets:" -ForegroundColor Cyan
    foreach ($target in $activeTargets) {
        $color = if ($target.health -eq "up") { "Green" } else { "Red" }
        $status = if ($target.health -eq "up") { "✅" } else { "❌" }
        Write-Host "  $status $($target.scrapePool): $($target.health)" -ForegroundColor $color
    }
} catch {
    Write-Host "⚠️  No se pudo verificar targets (Prometheus aún iniciando)" -ForegroundColor Yellow
}

Write-Host "`n🎉 ¡DESPLIEGUE COMPLETADO!" -ForegroundColor Green
Write-Host "`n📊 URLs de acceso:" -ForegroundColor Cyan
Write-Host "  Grafana:    http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com:3000" -ForegroundColor White
Write-Host "  Prometheus: http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com:9090" -ForegroundColor White
Write-Host "  Credentials: admin / admin123" -ForegroundColor Gray

Write-Host "`n📝 Próximos pasos:" -ForegroundColor Yellow
Write-Host "  1. Accede a Grafana y verifica los dashboards" -ForegroundColor White
Write-Host "  2. Verifica que todos los targets estén UP en Prometheus" -ForegroundColor White
Write-Host "  3. Si algún servicio sigue DOWN, verifica los logs" -ForegroundColor White

Write-Host "`n💡 Para verificar logs de un servicio:" -ForegroundColor Cyan
Write-Host "aws logs tail /ecs/<nombre-servicio> --follow --region us-east-1" -ForegroundColor Gray
