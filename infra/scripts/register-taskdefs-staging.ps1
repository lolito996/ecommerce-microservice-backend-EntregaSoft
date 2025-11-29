# Script simplificado para registrar Task Definitions
# Ejecuta esto primero antes de desplegar los servicios

$ErrorActionPreference = "Continue"

$ENVIRONMENT = "stage"
$AWS_REGION = "us-east-1"
$DOCKER_USER = "alejomunoz"
$DB_ENDPOINT = "stage-ecommerce-db.caju06qosdfc.us-east-1.rds.amazonaws.com:5432"
$ALB_DNS = "stage-ecommerce-alb-326144584.us-east-1.elb.amazonaws.com"

# Obtener contraseña de BD
Write-Host "🔐 Obteniendo contraseña..." -ForegroundColor Cyan
$DB_PASSWORD = aws secretsmanager get-secret-value --secret-id stage-ecommerce-db-master-password --query SecretString --output text

$SERVICES = @("service-discovery", "cloud-config", "api-gateway", "user-service", "product-service", "order-service")

Write-Host "📝 Registrando Task Definitions..." -ForegroundColor Yellow
Write-Host ""

foreach ($serviceName in $SERVICES) {
    Write-Host "Registrando: $serviceName" -ForegroundColor Cyan
    
    $port = switch ($serviceName) {
        "service-discovery" { 8761 }
        "cloud-config" { 8888 }
        "api-gateway" { 8080 }
        "user-service" { 8081 }
        "product-service" { 8082 }
        "order-service" { 8083 }
    }
    
    # JSON simplificado - usar variables correctamente
    $family = "$ENVIRONMENT-$serviceName"
    $image = "$DOCKER_USER/$serviceName`:latest"
    $logGroup = "/ecs/$ENVIRONMENT-$serviceName"
    $eurekaUrl = "http://$ALB_DNS`:8761/eureka/"
    $dbUrl = "jdbc:postgresql://$DB_ENDPOINT/ecommerce"
    
    $taskDefJson = @"
{
  "family": "$family",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::533924338325:role/$ENVIRONMENT-ecommerce-ecs-task-execution-role",
  "taskRoleArn": "arn:aws:iam::533924338325:role/$ENVIRONMENT-ecommerce-ecs-task-role",
  "containerDefinitions": [{
    "name": "$serviceName",
    "image": "$image",
    "portMappings": [{"containerPort": $port, "protocol": "tcp"}],
    "environment": [
      {"name": "SPRING_PROFILES_ACTIVE", "value": "stage"},
      {"name": "AWS_REGION", "value": "$AWS_REGION"},
      {"name": "EUREKA_CLIENT_SERVICEURL_DEFAULTZONE", "value": "$eurekaUrl"},
      {"name": "SPRING_DATASOURCE_URL", "value": "$dbUrl"},
      {"name": "SPRING_DATASOURCE_USERNAME", "value": "dbadmin"},
      {"name": "SPRING_DATASOURCE_PASSWORD", "value": "$DB_PASSWORD"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "$logGroup",
        "awslogs-region": "$AWS_REGION",
        "awslogs-stream-prefix": "ecs",
        "awslogs-create-group": "true"
      }
    }
  }]
}
"@
    
    $tempFile = "$env:TEMP\$serviceName-taskdef-new.json"
    $taskDefJson | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline
    
    try {
        $result = aws ecs register-task-definition --cli-input-json "file://$tempFile" --query "taskDefinition.family" --output text 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $serviceName registrado" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Error: $result" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "✅ Task Definitions registradas" -ForegroundColor Green
Write-Host ""
Write-Host "Ahora ejecuta: .\create-services-staging.ps1" -ForegroundColor Yellow
