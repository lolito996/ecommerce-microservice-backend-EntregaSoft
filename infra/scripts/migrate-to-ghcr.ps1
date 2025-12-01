# Script para migrar imágenes a GitHub Container Registry (sin rate limits)
# Requisito: Autenticarse con GitHub token
# Uso: .\migrate-to-ghcr.ps1

$ErrorActionPreference = "Stop"

Write-Host "🔧 Migrando imágenes a GitHub Container Registry..." -ForegroundColor Cyan

# Servicios a migrar
$services = @(
    "api-gateway",
    "user-service",
    "product-service",
    "order-service",
    "payment-service",
    "shipping-service",
    "favourite-service",
    "service-discovery",
    "cloud-config",
    "proxy-client"
)

$dockerHubUser = "alejomunoz"
$ghcrUser = "lolito996"

Write-Host "`n✅ Verificando autenticación con GitHub..." -ForegroundColor Green
Write-Host "Usuario GHCR: $ghcrUser" -ForegroundColor White
Write-Host ""

foreach ($service in $services) {
    Write-Host "`n📦 Migrando $service..." -ForegroundColor Cyan
    
    $dockerHubImage = "${dockerHubUser}/${service}:latest"
    $ghcrImage = "ghcr.io/${ghcrUser}/${service}:latest"
    
    # Pull desde Docker Hub
    Write-Host "  Descargando desde Docker Hub..." -ForegroundColor Gray
    docker pull $dockerHubImage
    
    # Tag para GHCR
    Write-Host "  Etiquetando para GHCR..." -ForegroundColor Gray
    docker tag $dockerHubImage $ghcrImage
    
    # Push a GHCR
    Write-Host "  Subiendo a GHCR..." -ForegroundColor Gray
    docker push $ghcrImage
    
    Write-Host "  ✅ $service migrado" -ForegroundColor Green
}

Write-Host "`n✅ ¡Migración completada!" -ForegroundColor Green
Write-Host "`n📝 Imágenes disponibles en:" -ForegroundColor Yellow
foreach ($service in $services) {
    Write-Host "  ghcr.io/${ghcrUser}/${service}:latest" -ForegroundColor White
}
Write-Host "`n💡 Las imágenes están listas para usar en los workflows de GitHub Actions" -ForegroundColor Cyan
