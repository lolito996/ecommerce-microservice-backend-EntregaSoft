# Script para desplegar el entorno de STAGING en AWS
# Similar al entorno DEV pero con configuraciones de staging

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  🚀 Desplegando Entorno de STAGING en AWS ECS" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Configuración
$stagePath = "infra\aws-environments\stage"
$projectRoot = Get-Location

Write-Host "`n📋 Configuración del Entorno STAGING:" -ForegroundColor Yellow
Write-Host "   • VPC CIDR: 10.1.0.0/16" -ForegroundColor White
Write-Host "   • Subnets Públicas: 10.1.1.0/24, 10.1.2.0/24" -ForegroundColor White
Write-Host "   • Subnets Privadas: 10.1.10.0/24, 10.1.20.0/24" -ForegroundColor White
Write-Host "   • NAT Gateways: ✅ Habilitados (2)" -ForegroundColor White
Write-Host "   • RDS: ✅ Single-AZ (db.t3.small)" -ForegroundColor White
Write-Host "   • ECS: FARGATE + FARGATE_SPOT" -ForegroundColor White
Write-Host "`n💰 Costo estimado: ~$200-300/mes" -ForegroundColor Yellow

$confirm = Read-Host "`n¿Deseas continuar con el despliegue de STAGING? (s/n)"

if ($confirm -ne "s") {
    Write-Host "❌ Despliegue cancelado" -ForegroundColor Red
    exit
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  PASO 1: Inicializar Terraform para STAGING" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Set-Location $stagePath

Write-Host "`n📦 Inicializando Terraform..." -ForegroundColor Yellow
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Error al inicializar Terraform" -ForegroundColor Red
    Set-Location $projectRoot
    exit 1
}

Write-Host "`n✅ Terraform inicializado correctamente" -ForegroundColor Green

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  PASO 2: Validar Configuración" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`n🔍 Validando configuración de Terraform..." -ForegroundColor Yellow
terraform validate

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ La configuración de Terraform tiene errores" -ForegroundColor Red
    Set-Location $projectRoot
    exit 1
}

Write-Host "`n✅ Configuración válida" -ForegroundColor Green

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  PASO 3: Planificar Infraestructura" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`n📊 Generando plan de ejecución..." -ForegroundColor Yellow
Write-Host "   (Esto puede tardar 1-2 minutos)" -ForegroundColor Gray

terraform plan "-out=stage.tfplan"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Error al generar el plan" -ForegroundColor Red
    Set-Location $projectRoot
    exit 1
}

Write-Host "`n✅ Plan generado exitosamente" -ForegroundColor Green
Write-Host "`n⚠️  REVISA EL PLAN DE ARRIBA:" -ForegroundColor Yellow
Write-Host "   • Recursos a crear" -ForegroundColor White
Write-Host "   • Costos estimados" -ForegroundColor White
Write-Host "   • Configuraciones" -ForegroundColor White

$continue = Read-Host "`n¿El plan se ve correcto? ¿Deseas aplicarlo? (s/n)"

if ($continue -ne "s") {
    Write-Host "❌ Aplicación cancelada" -ForegroundColor Red
    Set-Location $projectRoot
    exit
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  PASO 4: Aplicar Infraestructura" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`n🏗️  Creando infraestructura de STAGING..." -ForegroundColor Yellow
Write-Host "   ⏱️  Tiempo estimado: 10-15 minutos" -ForegroundColor Gray
Write-Host "   📊 Recursos a crear:" -ForegroundColor Gray
Write-Host "      • VPC con 4 subnets" -ForegroundColor White
Write-Host "      • 2 NAT Gateways" -ForegroundColor White
Write-Host "      • Application Load Balancer" -ForegroundColor White
Write-Host "      • ECS Cluster" -ForegroundColor White
Write-Host "      • RDS PostgreSQL (Single-AZ)" -ForegroundColor White
Write-Host "      • Security Groups e IAM Roles" -ForegroundColor White

terraform apply stage.tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Error al aplicar la infraestructura" -ForegroundColor Red
    Write-Host "   Revisa los logs de arriba para más detalles" -ForegroundColor Yellow
    Set-Location $projectRoot
    exit 1
}

Write-Host "`n✅ Infraestructura de STAGING creada exitosamente" -ForegroundColor Green

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  PASO 5: Obtener Outputs" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`n📝 Información de la infraestructura creada:" -ForegroundColor Yellow

$outputs = terraform output -json | ConvertFrom-Json

# Guardar outputs en un archivo
$deploymentInfo = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    environment = "stage"
    vpc_id = $outputs.vpc_id.value
    cluster_name = $outputs.ecs_cluster_name.value
    alb_dns = $outputs.alb_dns_name.value
}

$deploymentInfo | ConvertTo-Json | Out-File -FilePath "deployment-info.json" -Encoding UTF8

Write-Host "`n🌐 URLs y Recursos:" -ForegroundColor Cyan
Write-Host "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if ($outputs.alb_dns_name) {
    Write-Host "`n   📍 Application Load Balancer:" -ForegroundColor Yellow
    Write-Host "      http://$($outputs.alb_dns_name.value)" -ForegroundColor Green
}

if ($outputs.vpc_id) {
    Write-Host "`n   🌐 VPC ID:" -ForegroundColor Yellow
    Write-Host "      $($outputs.vpc_id.value)" -ForegroundColor White
}

if ($outputs.ecs_cluster_name) {
    Write-Host "`n   🐳 ECS Cluster:" -ForegroundColor Yellow
    Write-Host "      $($outputs.ecs_cluster_name.value)" -ForegroundColor White
}

Write-Host "`n   💾 Información guardada en: deployment-info.json" -ForegroundColor Gray

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  ✅ ENTORNO STAGING DESPLEGADO EXITOSAMENTE" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`n📋 Próximos Pasos:" -ForegroundColor Yellow
Write-Host "   1. ✅ Infraestructura lista" -ForegroundColor White
Write-Host "   2. 🐳 Desplegar microservicios a ECS" -ForegroundColor White
Write-Host "   3. 🔧 Configurar variables de entorno para STAGING" -ForegroundColor White
Write-Host "   4. ✅ Probar los servicios" -ForegroundColor White

Write-Host "`n🚀 Para desplegar los microservicios, ejecuta:" -ForegroundColor Cyan
Write-Host "   cd ..\..\scripts" -ForegroundColor Gray
Write-Host "   .\deploy-to-ecs.ps1 -Environment stage -ClusterName $($outputs.ecs_cluster_name.value)" -ForegroundColor Gray

Write-Host "`n💰 Costos Estimados STAGING:" -ForegroundColor Yellow
Write-Host "   • NAT Gateways: ~$65/mes (siempre activos)" -ForegroundColor White
Write-Host "   • ALB: ~$16/mes" -ForegroundColor White
Write-Host "   • ECS Fargate: ~$50-80/mes (cuando corre)" -ForegroundColor White
Write-Host "   • RDS: ~$37/mes (db.t3.small)" -ForegroundColor White
Write-Host "   • Otros: ~$20-30/mes" -ForegroundColor White
Write-Host "   ───────────────────────────────────────" -ForegroundColor Gray
Write-Host "   Total: ~$188-228/mes" -ForegroundColor Yellow

Write-Host "`n⚠️  IMPORTANTE:" -ForegroundColor Yellow
Write-Host "   • Este entorno está pensado para QA/Testing" -ForegroundColor White
Write-Host "   • Detén los servicios ECS cuando no los uses para ahorrar" -ForegroundColor White
Write-Host "   • RDS no es Multi-AZ (solo para staging)" -ForegroundColor White

Set-Location $projectRoot

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
