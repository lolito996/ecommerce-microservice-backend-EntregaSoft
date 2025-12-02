# Script para actualizar workflow a GitHub Container Registry
# Uso: .\update-workflow-to-ghcr.ps1

$ErrorActionPreference = "Stop"

$workflowFile = "..\..\. github\workflows\deploy-dev.yml"
$ghcrRegistry = "ghcr.io"
$ghcrUser = "gerson05"
$ghcrRepo = "ecommerce-microservice-backend-entregasoft"

Write-Host "🔧 Actualizando workflow para usar GitHub Container Registry..." -ForegroundColor Cyan

# Leer contenido del workflow
$content = Get-Content $workflowFile -Raw

Write-Host "`n📝 Cambios a realizar:" -ForegroundColor Yellow
Write-Host "  • Cambiar registry de docker.io a ghcr.io" -ForegroundColor White
Write-Host "  • Cambiar autenticación a GitHub token" -ForegroundColor White
Write-Host "  • Actualizar rutas de imágenes" -ForegroundColor White

# 1. Actualizar variable de entorno
$content = $content -replace 'DOCKER_USERNAME: alejomunoz', "DOCKER_REGISTRY: $ghcrRegistry`n  GHCR_USER: $ghcrUser`n  GHCR_REPO: $ghcrRepo"

# 2. Cambiar login de Docker Hub a GHCR en el job docker-build
$oldLogin = @'
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: \$\{\{ secrets\.DOCKER_USERNAME \}\}
          password: \$\{\{ secrets\.DOCKER_PASSWORD \}\}
'@

$newLogin = @'
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
'@

$content = $content -replace $oldLogin, $newLogin

# 3. Actualizar referencias de imágenes
$content = $content -replace '\$\{\{ secrets\.DOCKER_USERNAME \}\}/\$\{\{ matrix\.service \}\}', "ghcr.io/$ghcrUser/$ghcrRepo/`${{ matrix.service }}"
$content = $content -replace '\$\{\{ secrets\.DOCKER_USERNAME \}\}/\$service', "ghcr.io/$ghcrUser/$ghcrRepo/`$service"
$content = $content -replace '\$\{\{ env\.DOCKER_USERNAME \}\}/', "ghcr.io/$ghcrUser/$ghcrRepo/"

# Guardar cambios
$content | Out-File -FilePath $workflowFile -Encoding utf8 -NoNewline

Write-Host "`n✅ Workflow actualizado exitosamente!" -ForegroundColor Green

Write-Host "`n📋 Próximos pasos:" -ForegroundColor Cyan
Write-Host "  1. Ejecuta el script de migración: .\migrate-to-ghcr.ps1" -ForegroundColor White
Write-Host "  2. Commit y push los cambios del workflow" -ForegroundColor White
Write-Host "  3. El próximo push usará GHCR automáticamente (sin rate limits)" -ForegroundColor White

Write-Host "`n💡 Nota: Ya no necesitas DOCKER_USERNAME ni DOCKER_PASSWORD en secrets" -ForegroundColor Yellow
Write-Host "   GitHub Actions usa GITHUB_TOKEN automáticamente" -ForegroundColor Gray
