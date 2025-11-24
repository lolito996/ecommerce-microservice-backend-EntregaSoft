# Script para etiquetar y subir imágenes a Docker Hub
$DOCKER_USER = "alejomunoz"
$TAG = "latest"

$services = @(
    "api-gateway",
    "cloud-config",
    "service-discovery",
    "proxy-client",
    "user-service",
    "product-service",
    "favourite-service",
    "order-service",
    "shipping-service",
    "payment-service"
)

Write-Host "Etiquetando y subiendo imágenes a Docker Hub..." -ForegroundColor Green

foreach ($service in $services) {
    $localImage = "ecommerce-microservice-backend-entregasoft-$service-container:latest"
    $remoteImage = "$DOCKER_USER/$service" + ":$TAG"
    
    Write-Host "`nProcesando $service..." -ForegroundColor Yellow
    
    # Etiquetar imagen
    Write-Host "  Etiquetando: $localImage -> $remoteImage"
    docker tag $localImage $remoteImage
    
    if ($LASTEXITCODE -eq 0) {
        # Subir imagen
        Write-Host "  Subiendo: $remoteImage"
        docker push $remoteImage
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $service subido exitosamente" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Error al subir $service" -ForegroundColor Red
        }
    } else {
        Write-Host "  ✗ Error al etiquetar $service" -ForegroundColor Red
    }
}

Write-Host "`n¡Proceso completado!" -ForegroundColor Green
Write-Host "`nPara actualizar los pods en Kubernetes:" -ForegroundColor Cyan
Write-Host "cd infra\terraform\environments\staging" -ForegroundColor White
Write-Host '$env:NAMESPACE="microservices-staging"; $env:REGISTRY="alejomunoz"; $env:IMAGE_TAG="latest"; Get-ChildItem ..\..\..\..\k8s\base\*.yaml | ForEach-Object { $content = (Get-Content $_.FullName -Raw) -replace ''\$\{NAMESPACE\}'', $env:NAMESPACE -replace ''\$\{REGISTRY\}'', $env:REGISTRY -replace ''\$\{IMAGE_TAG\}'', $env:IMAGE_TAG; $content | kubectl apply -f - }' -ForegroundColor White
