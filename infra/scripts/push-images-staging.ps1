# Script para subir imágenes Docker a Docker Hub
# Ejecuta esto para hacer push de las 6 imágenes

$ErrorActionPreference = "Stop"

$DOCKER_USER = "alejomunoz"
$SERVICES = @("service-discovery", "cloud-config", "api-gateway", "user-service", "product-service", "order-service")

Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          Subiendo Imágenes Docker a Docker Hub                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verificar login en Docker Hub
Write-Host "🔐 Verificando sesión de Docker Hub..." -ForegroundColor Yellow
$loginStatus = docker info 2>&1 | Select-String "Username"
if (-not $loginStatus) {
    Write-Host "⚠ No estás logueado en Docker Hub" -ForegroundColor Red
    Write-Host "Ejecuta: docker login" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ Sesión activa" -ForegroundColor Green
Write-Host ""

$pushedImages = @()
$failedImages = @()

foreach ($service in $SERVICES) {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "📦 Procesando: $service" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $imageName = "$DOCKER_USER/$service`:latest"
    
    try {
        # Verificar si la imagen existe localmente
        Write-Host "  🔍 Verificando imagen local..." -ForegroundColor Cyan
        $imageExists = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "^$DOCKER_USER/$service`:latest$"
        
        if ($imageExists) {
            Write-Host "  ✓ Imagen encontrada localmente" -ForegroundColor Green
            
            # Hacer push
            Write-Host "  📤 Subiendo a Docker Hub..." -ForegroundColor Cyan
            docker push $imageName 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Push exitoso: $imageName" -ForegroundColor Green
                $pushedImages += $service
            } else {
                Write-Host "  ✗ Error al subir $imageName" -ForegroundColor Red
                $failedImages += $service
            }
        } else {
            Write-Host "  ⚠ Imagen no encontrada localmente" -ForegroundColor Yellow
            Write-Host "    Esperada: $imageName" -ForegroundColor Yellow
            $failedImages += $service
        }
    }
    catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
        $failedImages += $service
    }
    
    Write-Host ""
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    Resumen del Push                              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "✓ Imágenes subidas: $($pushedImages.Count)/6" -ForegroundColor Green

if ($pushedImages.Count -gt 0) {
    Write-Host ""
    Write-Host "Imágenes en Docker Hub:" -ForegroundColor Cyan
    foreach ($img in $pushedImages) {
        Write-Host "  • $DOCKER_USER/$img`:latest" -ForegroundColor White
    }
}

if ($failedImages.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠ Imágenes con problemas: $($failedImages.Count)" -ForegroundColor Red
    foreach ($img in $failedImages) {
        Write-Host "  • $img" -ForegroundColor Red
    }
}

Write-Host ""
if ($pushedImages.Count -eq 6) {
    Write-Host "🎉 ¡Todas las imágenes subidas exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ahora ejecuta para reiniciar los servicios:" -ForegroundColor Yellow
    Write-Host "   .\create-services-staging.ps1" -ForegroundColor White
} else {
    Write-Host "⚠ Algunas imágenes no se pudieron subir" -ForegroundColor Yellow
    Write-Host "Revisa los errores arriba y vuelve a intentar" -ForegroundColor Yellow
}
Write-Host ""
