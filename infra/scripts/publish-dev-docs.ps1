# 🚀 Script para Documentar el Entorno DEV en GitHub

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  📋 Documentando Entorno DEV en GitHub" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
$projectRoot = "C:\Users\alejo\OneDrive\Documentos\SEMESTRE VIII\ingesoft 5\backend ecommerce\ecommerce-microservice-backend-EntregaSoft"
Set-Location $projectRoot

Write-Host "`n✅ Directorio del proyecto:" -ForegroundColor Green
Write-Host "   $projectRoot" -ForegroundColor White

# Ver estado de git
Write-Host "`n📊 Estado de Git:" -ForegroundColor Yellow
git status --short

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Confirmar con el usuario
$continue = Read-Host "`n¿Deseas continuar con el commit y push? (s/n)"

if ($continue -ne "s") {
    Write-Host "❌ Operación cancelada" -ForegroundColor Red
    exit
}

Write-Host "`n🔄 Agregando archivos nuevos..." -ForegroundColor Cyan

# Agregar archivos específicos
$files = @(
    "DEV_ENVIRONMENT.md",
    ".github/GITHUB_ENVIRONMENTS_SETUP.md"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        git add $file
        Write-Host "  ✅ Agregado: $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  No encontrado: $file" -ForegroundColor Yellow
    }
}

Write-Host "`n📝 Creando commit..." -ForegroundColor Cyan

# Crear commit con mensaje descriptivo
$commitMessage = @"
docs: Add comprehensive DEV environment documentation

- Add DEV_ENVIRONMENT.md with complete AWS ECS setup details
- Add GitHub Environments setup guide
- Document all deployed services and their endpoints
- Include monitoring, troubleshooting, and cost information
- Add scripts for testing and verification

Features documented:
- 10 microservices running on AWS ECS Fargate
- Service Discovery (Eureka) configuration
- Application Load Balancer setup
- CloudWatch Logs integration
- Docker Hub image registry
- Cost optimization strategies
- GitHub Actions deployment workflows

All services verified and operational:
✅ Product Service
✅ User Service
✅ Order Service
✅ Payment Service
✅ Shipping Service
✅ Favourite Service
✅ Proxy Client
✅ API Gateway
✅ Service Discovery
✅ Cloud Config
"@

git commit -m $commitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Commit creado exitosamente" -ForegroundColor Green
} else {
    Write-Host "  ❌ Error al crear commit" -ForegroundColor Red
    exit 1
}

Write-Host "`n🚀 Haciendo push a GitHub..." -ForegroundColor Cyan

# Verificar rama actual
$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Host "  📍 Rama actual: $currentBranch" -ForegroundColor White

# Push
git push origin $currentBranch

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ ¡Push exitoso!" -ForegroundColor Green
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  🎉 Documentación subida a GitHub" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    Write-Host "`n📚 Archivos documentados:" -ForegroundColor Yellow
    foreach ($file in $files) {
        Write-Host "  ✓ $file" -ForegroundColor White
    }
    
    Write-Host "`n🔗 Próximos pasos:" -ForegroundColor Cyan
    Write-Host "  1. Ve a tu repositorio en GitHub" -ForegroundColor White
    Write-Host "  2. Revisa el archivo DEV_ENVIRONMENT.md" -ForegroundColor White
    Write-Host "  3. Configura GitHub Environments siguiendo:" -ForegroundColor White
    Write-Host "     .github/GITHUB_ENVIRONMENTS_SETUP.md" -ForegroundColor White
    Write-Host "  4. Configura los secrets necesarios" -ForegroundColor White
    Write-Host "  5. ¡Listo para CI/CD automático!" -ForegroundColor White
    
} else {
    Write-Host "`n❌ Error al hacer push" -ForegroundColor Red
    Write-Host "   Verifica tu conexión y permisos de GitHub" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
