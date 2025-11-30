# Script para configurar Grafana con dashboards y datasource de Prometheus
# Uso: .\configure-grafana.ps1

$ErrorActionPreference = "Stop"

$GRAFANA_URL = "http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com:3000"
$GRAFANA_USER = "admin"
$GRAFANA_PASSWORD = "admin123"
$PROMETHEUS_IP = "10.0.20.207"  # Se actualizará automáticamente

Write-Host "🔧 Configurando Grafana..." -ForegroundColor Cyan

# Crear credenciales de autenticación
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${GRAFANA_USER}:${GRAFANA_PASSWORD}"))
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    "Content-Type" = "application/json"
}

# 1. Obtener IP actual de Prometheus
Write-Host "`n📍 Obteniendo IP de Prometheus..." -ForegroundColor Yellow
$prometheusTaskArn = aws ecs list-tasks `
    --cluster dev-ecommerce-cluster `
    --service-name dev-prometheus `
    --region us-east-1 `
    --query 'taskArns[0]' `
    --output text

if ($prometheusTaskArn -and $prometheusTaskArn -ne "None") {
    $PROMETHEUS_IP = aws ecs describe-tasks `
        --cluster dev-ecommerce-cluster `
        --tasks $prometheusTaskArn `
        --region us-east-1 `
        --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' `
        --output text
    Write-Host "✅ Prometheus IP: $PROMETHEUS_IP" -ForegroundColor Green
}

# 2. Configurar datasource de Prometheus
Write-Host "`n📊 Configurando datasource de Prometheus..." -ForegroundColor Yellow

$datasource = @{
    name = "Prometheus"
    type = "prometheus"
    url = "http://${PROMETHEUS_IP}:9090"
    access = "proxy"
    isDefault = $true
    jsonData = @{
        timeInterval = "15s"
        httpMethod = "POST"
    }
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$GRAFANA_URL/api/datasources" -Method Post -Headers $headers -Body $datasource
    Write-Host "✅ Datasource creado: $($response.name)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "⚠️  Datasource ya existe, actualizando..." -ForegroundColor Yellow
        # Obtener ID del datasource existente
        $existingDs = Invoke-RestMethod -Uri "$GRAFANA_URL/api/datasources/name/Prometheus" -Headers $headers
        $response = Invoke-RestMethod -Uri "$GRAFANA_URL/api/datasources/$($existingDs.id)" -Method Put -Headers $headers -Body $datasource
        Write-Host "✅ Datasource actualizado" -ForegroundColor Green
    } else {
        Write-Host "❌ Error al crear datasource: $_" -ForegroundColor Red
    }
}

# 3. Importar dashboard de microservices-overview
Write-Host "`n📈 Importando dashboard Microservices Overview..." -ForegroundColor Yellow

$overviewJson = Get-Content -Path "..\..\monitoring\grafana\dashboards\microservices-overview.json" -Raw | ConvertFrom-Json

# Si el JSON ya tiene la estructura {dashboard: {...}}, usar directamente
if ($overviewJson.dashboard) {
    $dashboardPayload = $overviewJson | ConvertTo-Json -Depth 20
} else {
    $dashboardPayload = @{
        dashboard = $overviewJson
        overwrite = $true
        folderId = 0
    } | ConvertTo-Json -Depth 20
}

try {
    $response = Invoke-RestMethod -Uri "$GRAFANA_URL/api/dashboards/db" -Method Post -Headers $headers -Body $dashboardPayload
    Write-Host "✅ Dashboard 'Microservices Overview' importado: $($response.url)" -ForegroundColor Green
} catch {
    Write-Host "❌ Error al importar Microservices Overview: $_" -ForegroundColor Red
}

# 4. Importar dashboard de microservices-dashboard
Write-Host "`n📈 Importando dashboard Microservices Dashboard..." -ForegroundColor Yellow

$detailJson = Get-Content -Path "..\..\monitoring\grafana\dashboards\microservices-dashboard.json" -Raw | ConvertFrom-Json

# Si el JSON ya tiene la estructura {dashboard: {...}}, usar directamente
if ($detailJson.dashboard) {
    $dashboardPayload2 = $detailJson | ConvertTo-Json -Depth 20
} else {
    $dashboardPayload2 = @{
        dashboard = $detailJson
        overwrite = $true
        folderId = 0
    } | ConvertTo-Json -Depth 20
}

try {
    $response = Invoke-RestMethod -Uri "$GRAFANA_URL/api/dashboards/db" -Method Post -Headers $headers -Body $dashboardPayload2
    Write-Host "✅ Dashboard 'Microservices Dashboard' importado: $($response.url)" -ForegroundColor Green
} catch {
    Write-Host "❌ Error al importar Microservices Dashboard: $_" -ForegroundColor Red
}

Write-Host "`n✅ Configuración de Grafana completada!" -ForegroundColor Green
Write-Host "`n🔗 Accede a Grafana en: $GRAFANA_URL" -ForegroundColor Cyan
Write-Host "   Usuario: $GRAFANA_USER" -ForegroundColor White
Write-Host "   Contraseña: $GRAFANA_PASSWORD" -ForegroundColor White
Write-Host "`n📊 Dashboards disponibles:" -ForegroundColor Cyan
Write-Host "   - Microservices Overview" -ForegroundColor White
Write-Host "   - Microservices Dashboard" -ForegroundColor White
