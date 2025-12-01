#!/usr/bin/env pwsh
# Script para exponer Prometheus y Grafana en el ALB de desarrollo

$ErrorActionPreference = "Stop"

$CLUSTER = "dev-ecommerce-cluster"
$REGION = "us-east-1"
$ALB_ARN = "arn:aws:elasticloadbalancing:us-east-1:533924338325:loadbalancer/app/dev-ecommerce-alb/32d664e823a33a39"
$VPC_ID = "vpc-0b2c9353eedba8701"

Write-Host "🔧 Configurando acceso a Prometheus y Grafana via ALB..." -ForegroundColor Cyan
Write-Host ""

# 1. Crear Target Group para Prometheus
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "📦 Configurando Prometheus" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

# Verificar si el target group ya existe
$prometheusTgArn = aws elbv2 describe-target-groups `
    --region $REGION `
    --query "TargetGroups[?TargetGroupName=='dev-prometheus-tg'].TargetGroupArn" `
    --output text 2>$null

if (-not $prometheusTgArn -or $prometheusTgArn -eq "None") {
    Write-Host "`n📝 Creando Target Group para Prometheus..." -ForegroundColor Gray
    $prometheusTgArn = aws elbv2 create-target-group `
        --name dev-prometheus-tg `
        --protocol HTTP `
        --port 9090 `
        --vpc-id $VPC_ID `
        --target-type ip `
        --health-check-enabled `
        --health-check-path "/-/healthy" `
        --health-check-interval-seconds 30 `
        --health-check-timeout-seconds 5 `
        --healthy-threshold-count 2 `
        --unhealthy-threshold-count 3 `
        --region $REGION `
        --query 'TargetGroups[0].TargetGroupArn' `
        --output text
    
    Write-Host "✅ Target Group creado: $prometheusTgArn" -ForegroundColor Green
} else {
    Write-Host "✅ Target Group ya existe: $prometheusTgArn" -ForegroundColor Green
}

# Registrar tarea de Prometheus en el target group
Write-Host "`n🔗 Registrando Prometheus en Target Group..." -ForegroundColor Gray

$prometheusTaskArn = aws ecs list-tasks `
    --cluster $CLUSTER `
    --service-name dev-prometheus `
    --desired-status RUNNING `
    --region $REGION `
    --query 'taskArns[0]' `
    --output text

if ($prometheusTaskArn -and $prometheusTaskArn -ne "None") {
    $prometheusIp = aws ecs describe-tasks `
        --cluster $CLUSTER `
        --tasks $prometheusTaskArn `
        --region $REGION `
        --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address' `
        --output text
    
    aws elbv2 register-targets `
        --target-group-arn $prometheusTgArn `
        --targets "Id=$prometheusIp,Port=9090" `
        --region $REGION 2>$null
    
    Write-Host "✅ Prometheus registrado: $prometheusIp:9090" -ForegroundColor Green
}

# Crear listener rule para Prometheus (puerto 9090)
Write-Host "`n📋 Creando regla de listener para Prometheus..." -ForegroundColor Gray

$httpListenerArn = aws elbv2 describe-listeners `
    --load-balancer-arn $ALB_ARN `
    --region $REGION `
    --query 'Listeners[?Port==`80`].ListenerArn' `
    --output text

# Verificar si la regla ya existe
$existingRule = aws elbv2 describe-rules `
    --listener-arn $httpListenerArn `
    --region $REGION `
    --query "Rules[?Priority==\`90\`].RuleArn" `
    --output text 2>$null

if (-not $existingRule -or $existingRule -eq "None") {
    aws elbv2 create-rule `
        --listener-arn $httpListenerArn `
        --priority 90 `
        --conditions "Field=path-pattern,Values='/prometheus*'" `
        --actions "Type=forward,TargetGroupArn=$prometheusTgArn" `
        --region $REGION | Out-Null
    
    Write-Host "✅ Regla de listener creada (prioridad 90)" -ForegroundColor Green
} else {
    Write-Host "✅ Regla de listener ya existe" -ForegroundColor Green
}

# 2. Crear Target Group para Grafana
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "📊 Configurando Grafana" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

# Verificar si el target group ya existe
$grafanaTgArn = aws elbv2 describe-target-groups `
    --region $REGION `
    --query "TargetGroups[?TargetGroupName=='dev-grafana-tg'].TargetGroupArn" `
    --output text 2>$null

if (-not $grafanaTgArn -or $grafanaTgArn -eq "None") {
    Write-Host "`n📝 Creando Target Group para Grafana..." -ForegroundColor Gray
    $grafanaTgArn = aws elbv2 create-target-group `
        --name dev-grafana-tg `
        --protocol HTTP `
        --port 3000 `
        --vpc-id $VPC_ID `
        --target-type ip `
        --health-check-enabled `
        --health-check-path "/api/health" `
        --health-check-interval-seconds 30 `
        --health-check-timeout-seconds 5 `
        --healthy-threshold-count 2 `
        --unhealthy-threshold-count 3 `
        --region $REGION `
        --query 'TargetGroups[0].TargetGroupArn' `
        --output text
    
    Write-Host "✅ Target Group creado: $grafanaTgArn" -ForegroundColor Green
} else {
    Write-Host "✅ Target Group ya existe: $grafanaTgArn" -ForegroundColor Green
}

# Registrar tarea de Grafana en el target group
Write-Host "`n🔗 Registrando Grafana en Target Group..." -ForegroundColor Gray

$grafanaTaskArn = aws ecs list-tasks `
    --cluster $CLUSTER `
    --service-name dev-grafana `
    --desired-status RUNNING `
    --region $REGION `
    --query 'taskArns[0]' `
    --output text

if ($grafanaTaskArn -and $grafanaTaskArn -ne "None") {
    $grafanaIp = aws ecs describe-tasks `
        --cluster $CLUSTER `
        --tasks $grafanaTaskArn `
        --region $REGION `
        --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address' `
        --output text
    
    aws elbv2 register-targets `
        --target-group-arn $grafanaTgArn `
        --targets "Id=$grafanaIp,Port=3000" `
        --region $REGION 2>$null
    
    Write-Host "✅ Grafana registrado: $grafanaIp:3000" -ForegroundColor Green
}

# Crear listener rule para Grafana (puerto 3000)
Write-Host "`n📋 Creando regla de listener para Grafana..." -ForegroundColor Gray

$existingGrafanaRule = aws elbv2 describe-rules `
    --listener-arn $httpListenerArn `
    --region $REGION `
    --query "Rules[?Priority==\`91\`].RuleArn" `
    --output text 2>$null

if (-not $existingGrafanaRule -or $existingGrafanaRule -eq "None") {
    aws elbv2 create-rule `
        --listener-arn $httpListenerArn `
        --priority 91 `
        --conditions "Field=path-pattern,Values='/grafana*'" `
        --actions "Type=forward,TargetGroupArn=$grafanaTgArn" `
        --region $REGION | Out-Null
    
    Write-Host "✅ Regla de listener creada (prioridad 91)" -ForegroundColor Green
} else {
    Write-Host "✅ Regla de listener ya existe" -ForegroundColor Green
}

# Obtener DNS del ALB
$albDns = aws elbv2 describe-load-balancers `
    --load-balancer-arns $ALB_ARN `
    --region $REGION `
    --query 'LoadBalancers[0].DNSName' `
    --output text

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ Configuración completada" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green

Write-Host "`n🌐 URLs de acceso:" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Prometheus:" -ForegroundColor Yellow
Write-Host "   http://$albDns/prometheus" -ForegroundColor White
Write-Host ""
Write-Host "📊 Grafana:" -ForegroundColor Yellow
Write-Host "   http://$albDns/grafana" -ForegroundColor White
Write-Host "   Usuario: admin" -ForegroundColor Gray
Write-Host "   Contraseña: admin123" -ForegroundColor Gray
Write-Host ""
Write-Host "📈 Dashboards disponibles:" -ForegroundColor Cyan
Write-Host "   - Microservices Overview" -ForegroundColor White
Write-Host "   - Microservices Dashboard" -ForegroundColor White
Write-Host ""
Write-Host "💡 Nota: Si las URLs no funcionan, espera 1-2 minutos para que los health checks pasen" -ForegroundColor Yellow
