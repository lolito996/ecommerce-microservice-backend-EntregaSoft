#!/usr/bin/env pwsh
# Script para generar configuración de Prometheus para producción

$ErrorActionPreference = "Stop"

$CLUSTER = "prod-ecommerce-cluster"
$REGION = "us-east-1"

Write-Host "`n🔍 Descubriendo servicios ECS en producción...`n" -ForegroundColor Cyan

$services = @(
    @{name="api-gateway"; port=8080},
    @{name="user-service"; port=8081},
    @{name="product-service"; port=8082},
    @{name="order-service"; port=8083},
    @{name="payment-service"; port=8084},
    @{name="shipping-service"; port=8085},
    @{name="favourite-service"; port=8086},
    @{name="proxy-client"; port=8087},
    @{name="service-discovery"; port=8761},
    @{name="cloud-config"; port=9296}
)

$targets = @()

foreach ($svc in $services) {
    $serviceName = "prod-$($svc.name)"
    
    # Obtener ARN de la tarea activa
    $taskArn = aws ecs list-tasks `
        --cluster $CLUSTER `
        --service-name $serviceName `
        --desired-status RUNNING `
        --region $REGION `
        --query 'taskArns[0]' `
        --output text 2>$null
    
    if ($taskArn -and $taskArn -ne "None") {
        # Obtener IP privada de la tarea
        $privateIp = aws ecs describe-tasks `
            --cluster $CLUSTER `
            --tasks $taskArn `
            --region $REGION `
            --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address' `
            --output text 2>$null
        
        if ($privateIp -and $privateIp -ne "None") {
            $endpoint = "${privateIp}:$($svc.port)"
            Write-Host "  ✅ $($svc.name) : $endpoint" -ForegroundColor Green
            $targets += @{
                name = $svc.name
                ip = $privateIp
                port = $svc.port
            }
        } else {
            Write-Host "  ⚠️  $($svc.name) : No IP encontrada" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⚠️  $($svc.name) : Sin tareas activas" -ForegroundColor Yellow
    }
}

Write-Host "`n📝 Generando configuración de Prometheus...`n" -ForegroundColor Cyan

# Generar archivo prometheus-prod.yml
$config = @"
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'ecommerce-prod-ecs'
    environment: 'production'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

"@

foreach ($target in $targets) {
    $config += @"
  - job_name: '$($target.name)'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$($target.ip):$($target.port)']
        labels:
          service: '$($target.name)'
          environment: 'production'

"@
}

$outputPath = "prometheus\prometheus-prod.yml"
$config | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "✅ Configuración generada en: $outputPath" -ForegroundColor Green
Write-Host "`n📊 Servicios configurados: $($targets.Count)/$($services.Count)" -ForegroundColor Cyan

# Mostrar contenido
Write-Host "`n📄 Contenido del archivo:`n" -ForegroundColor Cyan
Get-Content $outputPath | Write-Host -ForegroundColor Gray

Write-Host "`n✅ Configuración lista para usar" -ForegroundColor Green
Write-Host "`n🚀 Próximos pasos:" -ForegroundColor Cyan
Write-Host "  1. Construir imagen de Prometheus: docker build -t ghcr.io/lolito996/prometheus-prod:latest ./monitoring/prometheus" -ForegroundColor White
Write-Host "  2. Push a GHCR: docker push ghcr.io/lolito996/prometheus-prod:latest" -ForegroundColor White
Write-Host "  3. Desplegar en ECS con esta configuración" -ForegroundColor White
