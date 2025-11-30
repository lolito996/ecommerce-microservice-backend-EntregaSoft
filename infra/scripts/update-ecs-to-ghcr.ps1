# Script para actualizar task definitions de ECS para usar GHCR
# Ejecutar DESPUÉS de migrar las imágenes a GHCR
# Uso: .\update-ecs-to-ghcr.ps1

$ErrorActionPreference = "Stop"

$CLUSTER = "dev-ecommerce-cluster"
$REGION = "us-east-1"
$ACCOUNT_ID = "533924338325"
$GHCR_REGISTRY = "ghcr.io/gerson05/ecommerce-microservice-backend-entregasoft"

Write-Host "🔧 Actualizando task definitions para usar GHCR..." -ForegroundColor Cyan

$services = @{
    "dev-api-gateway" = 8080
    "dev-user-service" = 8081
    "dev-product-service" = 8082
    "dev-order-service" = 8083
    "dev-payment-service" = 8084
    "dev-shipping-service" = 8085
    "dev-favourite-service" = 8086
    "dev-service-discovery" = 8761
    "dev-cloud-config" = 8888
    "dev-proxy-client" = 8087
}

foreach ($serviceName in $services.Keys) {
    $port = $services[$serviceName]
    $serviceShortName = $serviceName -replace '^dev-', ''
    
    Write-Host "`n📝 Actualizando $serviceName..." -ForegroundColor Yellow
    
    # Crear task definition con imagen de GHCR
    $taskDef = @"
{
  "family": "$serviceName",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/dev-ecommerce-ecs-task-execution-role",
  "taskRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/dev-ecommerce-ecs-task-role",
  "containerDefinitions": [{
    "name": "$serviceShortName",
    "image": "${GHCR_REGISTRY}/${serviceShortName}:latest",
    "portMappings": [{"containerPort": $port, "protocol": "tcp"}],
    "environment": [
      {"name": "SPRING_PROFILES_ACTIVE", "value": "dev"},
      {"name": "AWS_REGION", "value": "$REGION"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/$serviceName",
        "awslogs-region": "$REGION",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
"@
    
    # Guardar temporalmente
    $taskDef | Out-File -FilePath "task-def-$serviceName.json" -Encoding utf8
    
    # Registrar nueva task definition
    aws ecs register-task-definition --cli-input-json file://task-def-$serviceName.json --region $REGION | Out-Null
    
    # Limpiar archivo temporal
    Remove-Item "task-def-$serviceName.json"
    
    Write-Host "  ✅ Task definition actualizada" -ForegroundColor Green
}

Write-Host "`n✅ Todas las task definitions actualizadas!" -ForegroundColor Green

Write-Host "`n🚀 Ahora puedes desplegar los servicios:" -ForegroundColor Cyan
Write-Host ".\deploy-all-services-ghcr.ps1" -ForegroundColor White
