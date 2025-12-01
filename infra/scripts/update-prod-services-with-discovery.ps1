#!/usr/bin/env pwsh
# Script para actualizar servicios existentes con Service Discovery

$ErrorActionPreference = "Stop"

$CLUSTER = "prod-ecommerce-cluster"
$REGION = "us-east-1"
$NAMESPACE_ID = "ns-nhyybi4hheewu3ab"
$TARGET_GROUP_ARN = "arn:aws:elasticloadbalancing:us-east-1:533924338325:targetgroup/prod-ecommerce-api-gw-tg/81713d0500e73136"

# Obtener configuración de red
Write-Host "🔍 Obteniendo configuración de red..." -ForegroundColor Cyan
$vpcId = aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=prod" --query "Vpcs[0].VpcId" --output text --region $REGION
$subnets = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" "Name=tag:Type,Values=private" --query "Subnets[*].SubnetId" --output text --region $REGION
$subnetList = $subnets -replace '\s+', ','
$sgId = aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" "Name=group-name,Values=prod-ecommerce-ecs-tasks-sg" --query "SecurityGroups[0].GroupId" --output text --region $REGION

Write-Host "✅ VPC: $vpcId" -ForegroundColor Green
Write-Host "✅ Subnets: $subnetList" -ForegroundColor Green
Write-Host "✅ Security Group: $sgId" -ForegroundColor Green
Write-Host ""

$services = @(
    @{name="api-gateway"; port=8080; hasLB=$true},
    @{name="user-service"; port=8081; hasLB=$false},
    @{name="product-service"; port=8082; hasLB=$false},
    @{name="order-service"; port=8083; hasLB=$false},
    @{name="payment-service"; port=8084; hasLB=$false},
    @{name="shipping-service"; port=8085; hasLB=$false},
    @{name="favourite-service"; port=8086; hasLB=$false},
    @{name="proxy-client"; port=8087; hasLB=$false},
    @{name="service-discovery"; port=8761; hasLB=$false},
    @{name="cloud-config"; port=8888; hasLB=$false}
)

foreach ($svc in $services) {
    $serviceName = "prod-$($svc.name)"
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "🔄 Actualizando: $serviceName" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    # 1. Crear servicio en Service Discovery si no existe
    Write-Host "  🔍 Verificando Service Discovery..." -ForegroundColor Gray
    
    $existingDiscovery = aws servicediscovery list-services `
        --filters "Name=NAMESPACE_ID,Values=$NAMESPACE_ID" `
        --region $REGION `
        --query "Services[?Name=='$($svc.name)'].Id" `
        --output text
    
    if ($existingDiscovery) {
        Write-Host "  ✅ Service Discovery ya existe: $existingDiscovery" -ForegroundColor Green
        $discoveryServiceId = $existingDiscovery
    } else {
        Write-Host "  📝 Creando Service Discovery..." -ForegroundColor Gray
        $discoveryServiceId = aws servicediscovery create-service `
            --name "$($svc.name)" `
            --namespace-id $NAMESPACE_ID `
            --dns-config "NamespaceId=$NAMESPACE_ID,DnsRecords=[{Type=A,TTL=60}]" `
            --health-check-custom-config "FailureThreshold=1" `
            --region $REGION `
            --query 'Service.Id' `
            --output text
        
        Write-Host "  ✅ Service Discovery creado: $discoveryServiceId" -ForegroundColor Green
    }
    
    # 2. Obtener task definition actual
    Write-Host "  📄 Obteniendo task definition actual..." -ForegroundColor Gray
    
    $taskDefArn = aws ecs describe-services `
        --cluster $CLUSTER `
        --services $serviceName `
        --region $REGION `
        --query 'services[0].taskDefinition' `
        --output text
    
    if (-not $taskDefArn -or $taskDefArn -eq "None") {
        Write-Host "  ⚠️  Servicio no existe, saltando..." -ForegroundColor Yellow
        continue
    }
    
    # 3. Actualizar task definition con variables de entorno Eureka
    Write-Host "  📝 Actualizando task definition con Eureka..." -ForegroundColor Gray
    
    $taskDef = aws ecs describe-task-definition --task-definition $taskDefArn --region $REGION --query 'taskDefinition'
    $taskDefJson = $taskDef | ConvertFrom-Json
    
    # Agregar variables de entorno si no existen
    $envVars = $taskDefJson.containerDefinitions[0].environment
    $eurekaUrl = @{name="EUREKA_CLIENT_SERVICEURL_DEFAULTZONE"; value="http://service-discovery.prod.ecommerce.local:8761/eureka/"}
    $eurekaIp = @{name="EUREKA_INSTANCE_PREFER_IP_ADDRESS"; value="true"}
    
    if (-not ($envVars | Where-Object { $_.name -eq "EUREKA_CLIENT_SERVICEURL_DEFAULTZONE" })) {
        $taskDefJson.containerDefinitions[0].environment += $eurekaUrl
    }
    if (-not ($envVars | Where-Object { $_.name -eq "EUREKA_INSTANCE_PREFER_IP_ADDRESS" })) {
        $taskDefJson.containerDefinitions[0].environment += $eurekaIp
    }
    
    # Aumentar startPeriod a 90 segundos
    $taskDefJson.containerDefinitions[0].healthCheck.startPeriod = 90
    
    # Limpiar campos no necesarios
    $taskDefJson.PSObject.Properties.Remove('taskDefinitionArn')
    $taskDefJson.PSObject.Properties.Remove('revision')
    $taskDefJson.PSObject.Properties.Remove('status')
    $taskDefJson.PSObject.Properties.Remove('requiresAttributes')
    $taskDefJson.PSObject.Properties.Remove('compatibilities')
    $taskDefJson.PSObject.Properties.Remove('registeredAt')
    $taskDefJson.PSObject.Properties.Remove('registeredBy')
    
    # Guardar y registrar nueva task definition
    $taskDefJson | ConvertTo-Json -Depth 10 | Out-File -FilePath "temp-task-$serviceName.json" -Encoding UTF8
    
    $newTaskDefArn = aws ecs register-task-definition `
        --cli-input-json "file://temp-task-$serviceName.json" `
        --region $REGION `
        --query 'taskDefinition.taskDefinitionArn' `
        --output text
    
    Remove-Item "temp-task-$serviceName.json" -Force
    
    Write-Host "  ✅ Nueva task definition: $newTaskDefArn" -ForegroundColor Green
    
    # 4. Eliminar servicio ECS actual
    Write-Host "  🗑️  Eliminando servicio ECS actual..." -ForegroundColor Gray
    
    aws ecs update-service `
        --cluster $CLUSTER `
        --service $serviceName `
        --desired-count 0 `
        --region $REGION | Out-Null
    
    Write-Host "  ⏳ Esperando que las tareas terminen..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
    
    aws ecs delete-service `
        --cluster $CLUSTER `
        --service $serviceName `
        --region $REGION | Out-Null
    
    Write-Host "  ⏳ Esperando eliminación completa (60s)..." -ForegroundColor Gray
    Start-Sleep -Seconds 60
    
    # 5. Crear nuevo servicio con Service Discovery
    Write-Host "  🚀 Creando nuevo servicio con Service Discovery..." -ForegroundColor Gray
    
    if ($svc.hasLB) {
        aws ecs create-service `
            --cluster $CLUSTER `
            --service-name $serviceName `
            --task-definition "prod-$($svc.name)" `
            --desired-count 1 `
            --launch-type FARGATE `
            --platform-version LATEST `
            --network-configuration "awsvpcConfiguration={subnets=[$subnetList],securityGroups=[$sgId],assignPublicIp=DISABLED}" `
            --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=$($svc.name),containerPort=$($svc.port)" `
            --health-check-grace-period-seconds 120 `
            --service-registries "registryArn=arn:aws:servicediscovery:${REGION}:533924338325:service/$discoveryServiceId" `
            --region $REGION | Out-Null
    } else {
        aws ecs create-service `
            --cluster $CLUSTER `
            --service-name $serviceName `
            --task-definition "prod-$($svc.name)" `
            --desired-count 1 `
            --launch-type FARGATE `
            --platform-version LATEST `
            --network-configuration "awsvpcConfiguration={subnets=[$subnetList],securityGroups=[$sgId],assignPublicIp=DISABLED}" `
            --service-registries "registryArn=arn:aws:servicediscovery:${REGION}:533924338325:service/$discoveryServiceId" `
            --region $REGION | Out-Null
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Servicio recreado con Service Discovery" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Error al recrear servicio" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ Actualización completada" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "🔍 Verificar servicios:" -ForegroundColor Cyan
Write-Host "aws ecs list-services --cluster $CLUSTER --region $REGION" -ForegroundColor Gray
Write-Host ""
Write-Host "🔍 Verificar Service Discovery:" -ForegroundColor Cyan
Write-Host "aws servicediscovery list-services --filters Name=NAMESPACE_ID,Values=$NAMESPACE_ID --region $REGION" -ForegroundColor Gray
