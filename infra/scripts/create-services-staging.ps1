# Script para crear servicios ECS en Staging
# Ejecuta esto después de register-taskdefs-staging.ps1

$ErrorActionPreference = "Stop"

$ENVIRONMENT = "stage"
$ECS_CLUSTER = "stage-ecommerce-cluster"
$VPC_ID = "vpc-03816fc7d9d383282"
$SECURITY_GROUP_ID = "sg-0da7fc605fecda0ee"
$SUBNETS = @("subnet-0b611ed70814d2f09", "subnet-018fc0e7a0a3e8234")

$SERVICES = @(
    @{Name="service-discovery"; Priority=1},
    @{Name="cloud-config"; Priority=2},
    @{Name="api-gateway"; Priority=3},
    @{Name="user-service"; Priority=4},
    @{Name="product-service"; Priority=5},
    @{Name="order-service"; Priority=6}
)

Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          Creando Servicios ECS en Staging                       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$createdServices = @()

foreach ($service in $SERVICES | Sort-Object Priority) {
    $serviceName = $service.Name
    
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🚀 Creando: $serviceName (Prioridad $($service.Priority))" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    try {
        # Verificar si el servicio ya existe
        $existingService = aws ecs describe-services `
            --cluster $ECS_CLUSTER `
            --services $serviceName `
            --query "services[?status=='ACTIVE'].serviceName" `
            --output text 2>$null
        
        if ($existingService -eq $serviceName) {
            Write-Host "  ⚠ Servicio ya existe, actualizando..." -ForegroundColor Yellow
            
            aws ecs update-service `
                --cluster $ECS_CLUSTER `
                --service $serviceName `
                --task-definition "$ENVIRONMENT-$serviceName" `
                --desired-count 1 `
                --force-new-deployment | Out-Null
            
            Write-Host "  ✓ Servicio actualizado" -ForegroundColor Green
        }
        else {
            Write-Host "  📝 Creando nuevo servicio..." -ForegroundColor Cyan
            
            # Crear servicio sin load balancer (por ahora)
            aws ecs create-service `
                --cluster $ECS_CLUSTER `
                --service-name $serviceName `
                --task-definition "$ENVIRONMENT-$serviceName" `
                --desired-count 1 `
                --launch-type FARGATE `
                --network-configuration "awsvpcConfiguration={subnets=[$($SUBNETS -join ',')],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=DISABLED}" `
                --tags "key=Environment,value=$ENVIRONMENT" "key=ManagedBy,value=Terraform" | Out-Null
            
            Write-Host "  ✓ Servicio creado" -ForegroundColor Green
        }
        
        $createdServices += $serviceName
        
        # Esperar un poco para servicios críticos
        if ($service.Priority -le 2) {
            Write-Host "  ⏳ Esperando 30 segundos..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
        }
        else {
            Start-Sleep -Seconds 5
        }
    }
    catch {
        Write-Host "  ❌ Error: $_" -ForegroundColor Red
        Write-Host "  Continuando..." -ForegroundColor Yellow
    }
    
    Write-Host ""
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  Servicios Creados                               ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "✓ Servicios activos: $($createdServices.Count)/6" -ForegroundColor Green
Write-Host ""

if ($createdServices.Count -gt 0) {
    Write-Host "Servicios desplegados:" -ForegroundColor Cyan
    foreach ($svc in $createdServices) {
        Write-Host "  • $svc" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "📊 Verificar estado de los servicios:" -ForegroundColor Yellow
Write-Host "   aws ecs list-services --cluster $ECS_CLUSTER" -ForegroundColor White
Write-Host ""
Write-Host "📋 Ver detalles de un servicio:" -ForegroundColor Yellow
Write-Host "   aws ecs describe-services --cluster $ECS_CLUSTER --services service-discovery" -ForegroundColor White
Write-Host ""
Write-Host "📝 Ver logs:" -ForegroundColor Yellow
Write-Host "   aws logs tail /ecs/$ENVIRONMENT-service-discovery --follow" -ForegroundColor White
Write-Host ""
Write-Host "⚠ Nota: Los contenedores pueden tardar 2-3 minutos en iniciar" -ForegroundColor Yellow
Write-Host "   Es normal ver errores iniciales mientras se descargan las imágenes" -ForegroundColor Yellow
Write-Host ""
