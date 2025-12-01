# Script para importar el dashboard completo a Grafana
# Este script usa la API de Grafana para importar el dashboard automáticamente

$GRAFANA_URL = "http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com/grafana"
$GRAFANA_USER = "admin"
$GRAFANA_PASSWORD = "admin123"

Write-Host "`n📊 Importando Dashboard Completo a Grafana..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Crear credenciales base64
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${GRAFANA_USER}:${GRAFANA_PASSWORD}"))

# Leer el archivo del dashboard
$dashboardPath = ".\dashboards\complete-microservices-monitoring.json"
$dashboardContent = Get-Content $dashboardPath -Raw | ConvertFrom-Json

# Preparar el payload para la API de Grafana
$importPayload = @{
    dashboard = $dashboardContent.dashboard
    overwrite = $true
    inputs = @()
} | ConvertTo-Json -Depth 100

# Importar el dashboard
try {
    Write-Host "📤 Enviando dashboard a Grafana..." -ForegroundColor Yellow
    
    $headers = @{
        "Authorization" = "Basic $base64AuthInfo"
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-RestMethod -Uri "$GRAFANA_URL/api/dashboards/db" `
        -Method Post `
        -Headers $headers `
        -Body $importPayload `
        -ErrorAction Stop
    
    Write-Host "`n✅ Dashboard importado exitosamente!" -ForegroundColor Green
    Write-Host "🔗 URL: $GRAFANA_URL/d/$($response.uid)" -ForegroundColor Cyan
    Write-Host "`n📈 Dashboard disponible en:" -ForegroundColor Yellow
    Write-Host "   Dashboards > Browse > Complete Microservices Monitoring" -ForegroundColor White
    
} catch {
    Write-Host "`n❌ Error al importar dashboard:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`n💡 Importación manual:" -ForegroundColor Yellow
    Write-Host "1. Accede a: $GRAFANA_URL" -ForegroundColor White
    Write-Host "2. Ve a: Dashboards > Import" -ForegroundColor White
    Write-Host "3. Haz clic en 'Upload JSON file'" -ForegroundColor White
    Write-Host "4. Selecciona: complete-microservices-monitoring.json" -ForegroundColor White
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
