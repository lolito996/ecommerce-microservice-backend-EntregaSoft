# Script para desplegar Prometheus y Grafana en ECS Dev
# Uso: .\deploy-monitoring-ecs.ps1

$ErrorActionPreference = "Stop"

$CLUSTER = "dev-ecommerce-cluster"
$REGION = "us-east-1"
$ACCOUNT_ID = "533924338325"
$SUBNET_1 = "subnet-01d2294a2cfd1a3a5"
$SUBNET_2 = "subnet-0f19d0a4102bcb28a"
$SECURITY_GROUP = "sg-0e07474490306a56f"

Write-Host "🔧 Desplegando Prometheus y Grafana en ECS Dev..." -ForegroundColor Cyan

# 1. Crear log groups
Write-Host "`n📝 Creando CloudWatch Log Groups..." -ForegroundColor Yellow
aws logs create-log-group --log-group-name "/ecs/dev-prometheus" --region $REGION 2>$null
aws logs create-log-group --log-group-name "/ecs/dev-grafana" --region $REGION 2>$null
Write-Host "✅ Log groups creados" -ForegroundColor Green

# 2. Obtener IPs de servicios corriendo para configurar Prometheus
Write-Host "`n📍 Obteniendo IPs de microservicios..." -ForegroundColor Yellow

$runningServices = @{
    "dev-api-gateway" = @{ port = 8080; path = "/actuator/prometheus" }
    "dev-user-service" = @{ port = 8081; path = "/actuator/prometheus" }
    "dev-service-discovery" = @{ port = 8761; path = "/actuator/prometheus" }
    "dev-cloud-config" = @{ port = 8888; path = "/actuator/prometheus" }
    "dev-proxy-client" = @{ port = 8087; path = "/actuator/prometheus" }
}

$promTargets = @()

foreach ($serviceName in $runningServices.Keys) {
    $taskArn = aws ecs list-tasks --cluster $CLUSTER --service-name $serviceName --region $REGION --query 'taskArns[0]' --output text 2>$null
    
    if ($taskArn -and $taskArn -ne "None" -and $taskArn -ne "") {
        $ip = aws ecs describe-tasks --cluster $CLUSTER --tasks $taskArn --region $REGION --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' --output text 2>$null
        
        if ($ip) {
            $serviceInfo = $runningServices[$serviceName]
            $jobName = $serviceName -replace '^dev-', ''
            $promTargets += "  - job_name: '$jobName'`n    metrics_path: '$($serviceInfo.path)'`n    static_configs:`n      - targets: ['${ip}:$($serviceInfo.port)']"
            Write-Host "  ✓ $jobName : ${ip}:$($serviceInfo.port)" -ForegroundColor Green
        }
    }
}

$scrapeConfigs = $promTargets -join "`n"

# 3. Crear configuración de Prometheus
$prometheusYaml = @"
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

$scrapeConfigs
"@

# Codificar configuración en base64 para pasarla como variable de entorno
$prometheusYamlBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($prometheusYaml))

# 4. Registrar Task Definition para Prometheus
Write-Host "`n📝 Registrando Task Definition de Prometheus..." -ForegroundColor Yellow

$prometheusTaskDef = @"
{
  "family": "dev-prometheus",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/dev-ecommerce-ecs-task-execution-role",
  "taskRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/dev-ecommerce-ecs-task-role",
  "containerDefinitions": [{
    "name": "prometheus",
    "image": "alejomunoz/prometheus-ecommerce:latest",
    "portMappings": [{"containerPort": 9090, "protocol": "tcp"}],
    "environment": [
      {"name": "ENVIRONMENT", "value": "dev"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/dev-prometheus",
        "awslogs-region": "${REGION}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
"@

$prometheusTaskDef | Out-File -FilePath "prometheus-taskdef.json" -Encoding utf8
aws ecs register-task-definition --cli-input-json file://prometheus-taskdef.json --region $REGION | Out-Null
Remove-Item "prometheus-taskdef.json"
Write-Host "✅ Task Definition de Prometheus registrada" -ForegroundColor Green

# 3. Registrar Task Definition para Grafana
Write-Host "`n📝 Registrando Task Definition de Grafana..." -ForegroundColor Yellow

$grafanaTaskDef = @"
{
  "family": "dev-grafana",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/dev-ecommerce-ecs-task-execution-role",
  "taskRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/dev-ecommerce-ecs-task-role",
  "containerDefinitions": [{
    "name": "grafana",
    "image": "quay.io/grafana/grafana:latest",
    "portMappings": [{"containerPort": 3000, "protocol": "tcp"}],
    "environment": [
      {"name": "GF_SECURITY_ADMIN_USER", "value": "admin"},
      {"name": "GF_SECURITY_ADMIN_PASSWORD", "value": "admin123"},
      {"name": "GF_SERVER_ROOT_URL", "value": "http://localhost:3000"},
      {"name": "GF_INSTALL_PLUGINS", "value": "grafana-clock-panel,grafana-simple-json-datasource"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/dev-grafana",
        "awslogs-region": "${REGION}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
"@

$grafanaTaskDef | Out-File -FilePath "grafana-taskdef.json" -Encoding utf8
aws ecs register-task-definition --cli-input-json file://grafana-taskdef.json --region $REGION | Out-Null
Remove-Item "grafana-taskdef.json"
Write-Host "✅ Task Definition de Grafana registrada" -ForegroundColor Green

# 4. Crear o actualizar servicio de Prometheus
Write-Host "`n🚀 Creando/Actualizando servicio de Prometheus..." -ForegroundColor Yellow

$prometheusServiceExists = aws ecs describe-services `
    --cluster $CLUSTER `
    --services dev-prometheus `
    --region $REGION `
    --query 'services[0].status' `
    --output text 2>$null

if ($prometheusServiceExists -eq "ACTIVE") {
    Write-Host "Actualizando servicio existente..." -ForegroundColor Gray
    aws ecs update-service `
        --cluster $CLUSTER `
        --service dev-prometheus `
        --task-definition dev-prometheus `
        --desired-count 1 `
        --region $REGION | Out-Null
} else {
    Write-Host "Creando nuevo servicio..." -ForegroundColor Gray
    aws ecs create-service `
        --cluster $CLUSTER `
        --service-name dev-prometheus `
        --task-definition dev-prometheus `
        --desired-count 1 `
        --launch-type FARGATE `
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}" `
        --region $REGION | Out-Null
}
Write-Host "✅ Servicio de Prometheus desplegado" -ForegroundColor Green

# 5. Crear o actualizar servicio de Grafana
Write-Host "`n🚀 Creando/Actualizando servicio de Grafana..." -ForegroundColor Yellow

$grafanaServiceExists = aws ecs describe-services `
    --cluster $CLUSTER `
    --services dev-grafana `
    --region $REGION `
    --query 'services[0].status' `
    --output text 2>$null

if ($grafanaServiceExists -eq "ACTIVE") {
    Write-Host "Actualizando servicio existente..." -ForegroundColor Gray
    aws ecs update-service `
        --cluster $CLUSTER `
        --service dev-grafana `
        --task-definition dev-grafana `
        --desired-count 1 `
        --region $REGION | Out-Null
} else {
    Write-Host "Creando nuevo servicio..." -ForegroundColor Gray
    aws ecs create-service `
        --cluster $CLUSTER `
        --service-name dev-grafana `
        --task-definition dev-grafana `
        --desired-count 1 `
        --launch-type FARGATE `
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}" `
        --region $REGION | Out-Null
}
Write-Host "✅ Servicio de Grafana desplegado" -ForegroundColor Green

# 6. Esperar a que los servicios estén corriendo
Write-Host "`n⏳ Esperando a que los servicios inicien (esto puede tardar 2-3 minutos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 120

# 7. Obtener IPs privadas de las tareas
Write-Host "`n📍 Obteniendo IPs de los servicios..." -ForegroundColor Yellow

$prometheusTaskArn = aws ecs list-tasks `
    --cluster $CLUSTER `
    --service-name dev-prometheus `
    --region $REGION `
    --query 'taskArns[0]' `
    --output text

if ($prometheusTaskArn -and $prometheusTaskArn -ne "None") {
    $prometheusIp = aws ecs describe-tasks `
        --cluster $CLUSTER `
        --tasks $prometheusTaskArn `
        --region $REGION `
        --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' `
        --output text
    
    Write-Host "✅ Prometheus IP: $prometheusIp:9090" -ForegroundColor Green
}

$grafanaTaskArn = aws ecs list-tasks `
    --cluster $CLUSTER `
    --service-name dev-grafana `
    --region $REGION `
    --query 'taskArns[0]' `
    --output text

if ($grafanaTaskArn -and $grafanaTaskArn -ne "None") {
    $grafanaIp = aws ecs describe-tasks `
        --cluster $CLUSTER `
        --tasks $grafanaTaskArn `
        --region $REGION `
        --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' `
        --output text
    
    Write-Host "✅ Grafana IP: $grafanaIp:3000" -ForegroundColor Green
    Write-Host "   Usuario: admin" -ForegroundColor Cyan
    Write-Host "   Contraseña: admin123" -ForegroundColor Cyan
}

Write-Host "`n✅ Despliegue completado!" -ForegroundColor Green
Write-Host "`n📝 Notas:" -ForegroundColor Yellow
Write-Host "  - Los servicios están en subnets privadas (sin acceso desde internet)" -ForegroundColor Gray
Write-Host "  - Para acceder, necesitas estar en la VPC o usar un bastion host" -ForegroundColor Gray
Write-Host "  - Considera agregar Prometheus y Grafana al ALB para acceso externo" -ForegroundColor Gray

Write-Host "`n🔗 Próximos pasos:" -ForegroundColor Cyan
Write-Host "  1. Configurar datasource de Prometheus en Grafana: http://$prometheusIp:9090" -ForegroundColor White
Write-Host "  2. Importar dashboards desde monitoring/grafana/dashboards/" -ForegroundColor White
Write-Host "  3. Verificar que Prometheus esté recolectando métricas de los microservicios" -ForegroundColor White
