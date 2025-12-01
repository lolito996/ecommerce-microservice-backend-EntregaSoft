#!/usr/bin/env pwsh
# Script para desplegar Prometheus y Grafana en ECS usando GHCR

$ErrorActionPreference = "Stop"

$CLUSTER = "dev-ecommerce-cluster"
$REGION = "us-east-1"
$GHCR_USER = "lolito996"

Write-Host "🚀 Desplegando Prometheus y Grafana en ECS..." -ForegroundColor Cyan
Write-Host ""

# Obtener configuración de red
Write-Host "🔍 Obteniendo configuración de red..." -ForegroundColor Gray
$vpcId = aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=dev" --query "Vpcs[0].VpcId" --output text --region $REGION
$subnets = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" "Name=tag:Type,Values=private" --query "Subnets[*].SubnetId" --output text --region $REGION
$subnetList = $subnets -replace '\s+', ','
$sgId = aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" "Name=group-name,Values=dev-ecommerce-ecs-tasks-sg" --query "SecurityGroups[0].GroupId" --output text --region $REGION

Write-Host "✅ VPC: $vpcId" -ForegroundColor Green
Write-Host "✅ Subnets: $subnetList" -ForegroundColor Green
Write-Host "✅ Security Group: $sgId" -ForegroundColor Green
Write-Host ""

# 1. Desplegar Prometheus
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "📦 Desplegando Prometheus" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

# Crear log group
Write-Host "`n📋 Creando log group..." -ForegroundColor Gray
aws logs create-log-group --log-group-name "/ecs/dev-prometheus" --region $REGION 2>$null

# Registrar task definition de Prometheus
Write-Host "📄 Registrando task definition de Prometheus..." -ForegroundColor Gray

$prometheusTaskDef = @"
{
  "family": "dev-prometheus",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::533924338325:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::533924338325:role/ecsTaskExecutionRole",
  "containerDefinitions": [{
    "name": "prometheus",
    "image": "ghcr.io/$GHCR_USER/prometheus-dev:latest",
    "portMappings": [{"containerPort": 9090, "protocol": "tcp"}],
    "environment": [
      {"name": "ENVIRONMENT", "value": "dev"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/dev-prometheus",
        "awslogs-region": "$REGION",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "healthCheck": {
      "command": ["CMD-SHELL", "wget -q --spider http://localhost:9090/-/healthy || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 60
    }
  }]
}
"@

$prometheusTaskDef | Out-File -FilePath "task-prometheus.json" -Encoding UTF8
$prometheusTaskDefArn = aws ecs register-task-definition `
    --cli-input-json "file://task-prometheus.json" `
    --region $REGION `
    --query 'taskDefinition.taskDefinitionArn' `
    --output text

Remove-Item "task-prometheus.json" -Force

Write-Host "✅ Task definition registrada: $prometheusTaskDefArn" -ForegroundColor Green

# Verificar si el servicio ya existe
$existingPrometheus = aws ecs describe-services `
    --cluster $CLUSTER `
    --services dev-prometheus `
    --region $REGION `
    --query 'services[?status==`ACTIVE`].serviceName' `
    --output text 2>$null

if ($existingPrometheus) {
    Write-Host "🔄 Actualizando servicio existente..." -ForegroundColor Yellow
    aws ecs update-service `
        --cluster $CLUSTER `
        --service dev-prometheus `
        --task-definition dev-prometheus `
        --force-new-deployment `
        --region $REGION | Out-Null
    Write-Host "✅ Servicio actualizado" -ForegroundColor Green
} else {
    Write-Host "📝 Creando servicio..." -ForegroundColor Gray
    aws ecs create-service `
        --cluster $CLUSTER `
        --service-name dev-prometheus `
        --task-definition dev-prometheus `
        --desired-count 1 `
        --launch-type FARGATE `
        --platform-version LATEST `
        --network-configuration "awsvpcConfiguration={subnets=[$subnetList],securityGroups=[$sgId],assignPublicIp=DISABLED}" `
        --region $REGION | Out-Null
    Write-Host "✅ Servicio creado" -ForegroundColor Green
}

# 2. Desplegar Grafana
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "📊 Desplegando Grafana" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

# Crear log group
Write-Host "`n📋 Creando log group..." -ForegroundColor Gray
aws logs create-log-group --log-group-name "/ecs/dev-grafana" --region $REGION 2>$null

# Registrar task definition de Grafana
Write-Host "📄 Registrando task definition de Grafana..." -ForegroundColor Gray

$grafanaTaskDef = @"
{
  "family": "dev-grafana",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::533924338325:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::533924338325:role/ecsTaskExecutionRole",
  "containerDefinitions": [{
    "name": "grafana",
    "image": "ghcr.io/$GHCR_USER/grafana-dev:latest",
    "portMappings": [{"containerPort": 3000, "protocol": "tcp"}],
    "environment": [
      {"name": "GF_SECURITY_ADMIN_PASSWORD", "value": "admin123"},
      {"name": "GF_USERS_ALLOW_SIGN_UP", "value": "false"},
      {"name": "GF_SERVER_ROOT_URL", "value": "http://dev-ecommerce-alb-1748132991.us-east-1.elb.amazonaws.com:3000"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/dev-grafana",
        "awslogs-region": "$REGION",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "healthCheck": {
      "command": ["CMD-SHELL", "wget -q --spider http://localhost:3000/api/health || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 60
    }
  }]
}
"@

$grafanaTaskDef | Out-File -FilePath "task-grafana.json" -Encoding UTF8
$grafanaTaskDefArn = aws ecs register-task-definition `
    --cli-input-json "file://task-grafana.json" `
    --region $REGION `
    --query 'taskDefinition.taskDefinitionArn' `
    --output text

Remove-Item "task-grafana.json" -Force

Write-Host "✅ Task definition registrada: $grafanaTaskDefArn" -ForegroundColor Green

# Verificar si el servicio ya existe
$existingGrafana = aws ecs describe-services `
    --cluster $CLUSTER `
    --services dev-grafana `
    --region $REGION `
    --query 'services[?status==`ACTIVE`].serviceName' `
    --output text 2>$null

if ($existingGrafana) {
    Write-Host "🔄 Actualizando servicio existente..." -ForegroundColor Yellow
    aws ecs update-service `
        --cluster $CLUSTER `
        --service dev-grafana `
        --task-definition dev-grafana `
        --force-new-deployment `
        --region $REGION | Out-Null
    Write-Host "✅ Servicio actualizado" -ForegroundColor Green
} else {
    Write-Host "📝 Creando servicio..." -ForegroundColor Gray
    aws ecs create-service `
        --cluster $CLUSTER `
        --service-name dev-grafana `
        --task-definition dev-grafana `
        --desired-count 1 `
        --launch-type FARGATE `
        --platform-version LATEST `
        --network-configuration "awsvpcConfiguration={subnets=[$subnetList],securityGroups=[$sgId],assignPublicIp=DISABLED}" `
        --region $REGION | Out-Null
    Write-Host "✅ Servicio creado" -ForegroundColor Green
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ Despliegue completado" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green

Write-Host "`n⏳ Esperando a que los servicios inicien..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Obtener IPs de los servicios
Write-Host "`n📍 Obteniendo IPs de los servicios..." -ForegroundColor Cyan

$prometheusTask = aws ecs list-tasks --cluster $CLUSTER --service-name dev-prometheus --region $REGION --query 'taskArns[0]' --output text
if ($prometheusTask -and $prometheusTask -ne "None") {
    $prometheusIp = aws ecs describe-tasks --cluster $CLUSTER --tasks $prometheusTask --region $REGION --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address' --output text
    Write-Host "  📦 Prometheus: http://$prometheusIp`:9090" -ForegroundColor Green
}

$grafanaTask = aws ecs list-tasks --cluster $CLUSTER --service-name dev-grafana --region $REGION --query 'taskArns[0]' --output text
if ($grafanaTask -and $grafanaTask -ne "None") {
    $grafanaIp = aws ecs describe-tasks --cluster $CLUSTER --tasks $grafanaTask --region $REGION --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address' --output text
    Write-Host "  📊 Grafana: http://$grafanaIp`:3000 (admin/admin123)" -ForegroundColor Green
}

Write-Host "`n💡 Para acceder desde fuera de la VPC, configura reglas en el ALB o usa port forwarding" -ForegroundColor Yellow
