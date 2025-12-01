#!/usr/bin/env pwsh
# Script para crear servicios ECS de producción

$ErrorActionPreference = "Stop"

$CLUSTER = "prod-ecommerce-cluster"
$REGION = "us-east-1"
$TARGET_GROUP_ARN = "arn:aws:elasticloadbalancing:us-east-1:533924338325:targetgroup/prod-ecommerce-api-gw-tg/81713d0500e73136"
$NAMESPACE_ID = "ns-nhyybi4hheewu3ab"  # Service Discovery namespace

# Obtener VPC y Subnets del cluster
Write-Host "🔍 Obteniendo configuración de red..." -ForegroundColor Cyan
$vpcId = aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=prod" --query "Vpcs[0].VpcId" --output text --region $REGION
$subnets = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" "Name=tag:Type,Values=private" --query "Subnets[*].SubnetId" --output text --region $REGION
$subnetList = $subnets -replace '\s+', ','

# Obtener security group del ECS (buscar por varios criterios)
$sgId = aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" "Name=group-name,Values=prod-ecommerce-ecs-tasks-sg" --query "SecurityGroups[0].GroupId" --output text --region $REGION

if ($sgId -eq "None" -or -not $sgId) {
    Write-Host "❌ No se encontró Security Group para ECS en VPC $vpcId" -ForegroundColor Red
    Write-Host "Listando security groups disponibles:" -ForegroundColor Yellow
    aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" --query "SecurityGroups[*].[GroupId,GroupName,Tags[?Key=='Name'].Value|[0]]" --output table --region $REGION
    exit 1
}

Write-Host "✅ VPC: $vpcId" -ForegroundColor Green
Write-Host "✅ Subnets: $subnetList" -ForegroundColor Green
Write-Host "✅ Security Group: $sgId" -ForegroundColor Green
Write-Host ""

# Servicios a crear
$services = @(
    @{name="api-gateway"; port=8080; cpu=512; memory=1024; priority=100},
    @{name="user-service"; port=8081; cpu=512; memory=1024; priority=101},
    @{name="product-service"; port=8082; cpu=512; memory=1024; priority=102},
    @{name="order-service"; port=8083; cpu=512; memory=1024; priority=103},
    @{name="payment-service"; port=8084; cpu=512; memory=1024; priority=104},
    @{name="shipping-service"; port=8085; cpu=512; memory=1024; priority=105},
    @{name="favourite-service"; port=8086; cpu=512; memory=1024; priority=106},
    @{name="proxy-client"; port=8087; cpu=512; memory=1024; priority=107},
    @{name="service-discovery"; port=8761; cpu=512; memory=1024; priority=108},
    @{name="cloud-config"; port=8888; cpu=512; memory=1024; priority=109}
)

foreach ($svc in $services) {
    $serviceName = "prod-$($svc.name)"
    $taskFamily = "prod-$($svc.name)"
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "📦 Creando servicio: $serviceName" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    # Verificar si el servicio ya existe
    $existingService = aws ecs describe-services `
        --cluster $CLUSTER `
        --services $serviceName `
        --region $REGION `
        --query "services[?status=='ACTIVE'].serviceName" `
        --output text 2>$null
    
    if ($existingService) {
        Write-Host "⚠️  Servicio $serviceName ya existe, saltando..." -ForegroundColor Yellow
        continue
    }
    
    # Crear log group
    Write-Host "  📋 Creando log group..." -ForegroundColor Gray
    aws logs create-log-group `
        --log-group-name "/ecs/$serviceName" `
        --region $REGION 2>$null
    
    # Registrar task definition
    Write-Host "  📄 Registrando task definition..." -ForegroundColor Gray
    
    $taskDef = @"
{
  "family": "$taskFamily",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "$($svc.cpu)",
  "memory": "$($svc.memory)",
  "executionRoleArn": "arn:aws:iam::533924338325:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::533924338325:role/ecsTaskExecutionRole",
  "containerDefinitions": [{
    "name": "$($svc.name)",
    "image": "ghcr.io/lolito996/$($svc.name):latest",
    "portMappings": [{"containerPort": $($svc.port), "protocol": "tcp"}],
    "environment": [
      {"name": "SPRING_PROFILES_ACTIVE", "value": "prod"},
      {"name": "AWS_REGION", "value": "$REGION"},
      {"name": "EUREKA_CLIENT_SERVICEURL_DEFAULTZONE", "value": "http://service-discovery.prod.ecommerce.local:8761/eureka/"},
      {"name": "EUREKA_INSTANCE_PREFER_IP_ADDRESS", "value": "true"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/$serviceName",
        "awslogs-region": "$REGION",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -f http://localhost:$($svc.port)/actuator/health || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 90
    }
  }]
}
"@
    
    $taskDef | Out-File -FilePath "task-$serviceName.json" -Encoding UTF8
    
    $taskDefArn = aws ecs register-task-definition `
        --cli-input-json "file://task-$serviceName.json" `
        --region $REGION `
        --query 'taskDefinition.taskDefinitionArn' `
        --output text
    
    Remove-Item "task-$serviceName.json" -Force
    
    if (-not $taskDefArn) {
        Write-Host "❌ Error al registrar task definition para $serviceName" -ForegroundColor Red
        continue
    }
    
    Write-Host "  ✅ Task definition registrada: $taskDefArn" -ForegroundColor Green
    
    # Crear servicio en Service Discovery primero
    Write-Host "  🔍 Registrando en Service Discovery..." -ForegroundColor Gray
    
    $discoveryService = aws servicediscovery create-service `
        --name "$($svc.name)" `
        --namespace-id $NAMESPACE_ID `
        --dns-config "NamespaceId=$NAMESPACE_ID,DnsRecords=[{Type=A,TTL=60}]" `
        --health-check-custom-config "FailureThreshold=1" `
        --region $REGION `
        --query 'Service.Id' `
        --output text
    
    Write-Host "  ✅ Service Discovery ID: $discoveryService" -ForegroundColor Green
    
    # Crear servicio ECS
    Write-Host "  🚀 Creando servicio ECS..." -ForegroundColor Gray
    
    # Determinar si es api-gateway (usa target group) o servicio interno
    if ($svc.name -eq "api-gateway") {
        aws ecs create-service `
            --cluster $CLUSTER `
            --service-name $serviceName `
            --task-definition $taskFamily `
            --desired-count 1 `
            --launch-type FARGATE `
            --platform-version LATEST `
            --network-configuration "awsvpcConfiguration={subnets=[$subnetList],securityGroups=[$sgId],assignPublicIp=DISABLED}" `
            --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=$($svc.name),containerPort=$($svc.port)" `
            --health-check-grace-period-seconds 120 `
            --service-registries "registryArn=arn:aws:servicediscovery:${REGION}:533924338325:service/$discoveryService" `
            --region $REGION | Out-Null
    } else {
        aws ecs create-service `
            --cluster $CLUSTER `
            --service-name $serviceName `
            --task-definition $taskFamily `
            --desired-count 1 `
            --launch-type FARGATE `
            --platform-version LATEST `
            --network-configuration "awsvpcConfiguration={subnets=[$subnetList],securityGroups=[$sgId],assignPublicIp=DISABLED}" `
            --service-registries "registryArn=arn:aws:servicediscovery:${REGION}:533924338325:service/$discoveryService" `
            --region $REGION | Out-Null
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Servicio $serviceName creado exitosamente" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Error al crear servicio $serviceName" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ Proceso completado" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "🔍 Verificar servicios creados:" -ForegroundColor Cyan
Write-Host "aws ecs list-services --cluster $CLUSTER --region $REGION" -ForegroundColor Gray
Write-Host ""
Write-Host "🌐 URL del API Gateway:" -ForegroundColor Cyan
Write-Host "http://prod-ecommerce-alb-1555495191.us-east-1.elb.amazonaws.com/api" -ForegroundColor White
