#!/usr/bin/env pwsh
# Check Eureka Service Registration
# Verifies which services are successfully registered with Eureka

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment
)

$ErrorActionPreference = "Stop"

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║              VERIFICACIÓN DE REGISTRO EN EUREKA                               ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$clusterName = "$Environment-ecommerce-cluster"

Write-Host "Cluster: $clusterName`n" -ForegroundColor Gray

# Lista de servicios esperados
$expectedServices = @(
    "CLOUD-CONFIG",
    "API-GATEWAY", 
    "USER-SERVICE",
    "PRODUCT-SERVICE",
    "ORDER-SERVICE",
    "PAYMENT-SERVICE",
    "SHIPPING-SERVICE",
    "FAVOURITE-SERVICE",
    "PROXY-CLIENT"
)

Write-Host "Verificando logs de registro en Eureka...`n" -ForegroundColor Yellow

$registered = @()
$notRegistered = @()

foreach ($serviceName in $expectedServices) {
    Write-Host "Checking $serviceName..." -ForegroundColor Gray
    
    # Buscar en logs mensajes de registro exitoso
    $logs = aws logs tail /ecs/$Environment-ecommerce --since 10m --format short --filter-pattern $serviceName 2>$null
    
    if ($logs -match "DiscoveryClient.*registration status: 204" -or 
        $logs -match "Registered.*with Eureka" -or
        $logs -match "DiscoveryClient.*heartbeat.*200") {
        $registered += $serviceName
        Write-Host "  ✓ $serviceName registrado" -ForegroundColor Green
    } else {
        $notRegistered += $serviceName
        Write-Host "  ✗ $serviceName no confirmado" -ForegroundColor Red
    }
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "RESUMEN DE REGISTRO" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "Servicios Registrados: $($registered.Count)/$($expectedServices.Count)" -ForegroundColor Green
if ($registered.Count -gt 0) {
    $registered | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor Green }
}

if ($notRegistered.Count -gt 0) {
    Write-Host "`nServicios No Confirmados: $($notRegistered.Count)" -ForegroundColor Yellow
    $notRegistered | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
}

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                     INFORMACIÓN DE ACCESO A DASHBOARDS                        ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Obtener IP de Eureka
$eurekaTaskArn = aws ecs list-tasks --cluster $clusterName --service-name "$Environment-service-discovery" --query 'taskArns[0]' --output text
if ($eurekaTaskArn -and $eurekaTaskArn -ne "None") {
    $eurekaIp = aws ecs describe-tasks --cluster $clusterName --tasks $eurekaTaskArn --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address' --output text
    Write-Host "Eureka Dashboard (Red Privada): http://${eurekaIp}:8761" -ForegroundColor Yellow
}

Write-Host @"

NOTA: Los dashboards de Eureka y Zipkin están en la red privada de AWS.
Para acceder necesitas:
  1. Configurar un Bastion Host
  2. Usar AWS Session Manager
  3. Configurar un túnel SSH

Para verificar el registro, también puedes:
  - Probar los endpoints de las APIs (si funcionan, están registrados)
  - Revisar los logs de CloudWatch

"@ -ForegroundColor Gray
