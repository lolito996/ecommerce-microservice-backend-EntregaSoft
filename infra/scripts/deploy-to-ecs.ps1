#!/usr/bin/env pwsh
# Deploy Microservices to ECS
# Creates ECS Task Definitions and Services from Docker Hub images

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment,
    
    [string]$DockerRegistry = "alejomunoz",
    [string]$ImageTag = "latest",
    
    [switch]$SkipTest
)

$ErrorActionPreference = "Stop"

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                    Deploy Microservices to ECS                               ║
║                    E-Commerce Platform                                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

Environment:      $Environment
Docker Registry:  $DockerRegistry
Image Tag:        $ImageTag

"@ -ForegroundColor Cyan

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Test Docker images first (unless skipped)
if (-not $SkipTest) {
    Write-Host "Testing Docker images..." -ForegroundColor Yellow
    $testScript = Join-Path $scriptDir "test-docker-images.ps1"
    
    if (Test-Path $testScript) {
        & $testScript -ImagePrefix $DockerRegistry
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`n⚠️  Image tests failed. Continue anyway?" -ForegroundColor Yellow
            $continue = Read-Host "Continue? (y/N)"
            if ($continue -ne "y") {
                exit 1
            }
        }
    }
}

# Get infrastructure outputs
Write-Host "`nRetrieving infrastructure details..." -ForegroundColor Yellow
$envDir = Join-Path $scriptDir ".." "aws-environments" $Environment

if (-not (Test-Path $envDir)) {
    Write-Host "ERROR: Environment not found: $envDir" -ForegroundColor Red
    exit 1
}

Push-Location $envDir

try {
    # Get Terraform outputs
    $vpcId = terraform output -raw vpc_id
    $clusterName = terraform output -raw ecs_cluster_name
    $albDns = terraform output -raw alb_dns_name
    $executionRoleArn = terraform output -raw ecs_task_execution_role_arn
    $taskRoleArn = terraform output -raw ecs_task_role_arn
    
    Write-Host "✓ VPC ID: $vpcId" -ForegroundColor Green
    Write-Host "✓ ECS Cluster: $clusterName" -ForegroundColor Green
    Write-Host "✓ ALB DNS: $albDns" -ForegroundColor Green
    Write-Host "✓ Execution Role: $executionRoleArn" -ForegroundColor Green
    
} finally {
    Pop-Location
}

# Create ECS Task Definitions using AWS CLI
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Creating ECS Task Definitions" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$services = @(
    @{Name="service-discovery"; Port=8761; CPU=512; Memory=1024}
    @{Name="cloud-config"; Port=9296; CPU=512; Memory=1024}
    @{Name="api-gateway"; Port=8080; CPU=512; Memory=1024}
    @{Name="user-service"; Port=8700; CPU=512; Memory=1024}
    @{Name="product-service"; Port=8500; CPU=512; Memory=1024}
    @{Name="order-service"; Port=8300; CPU=512; Memory=1024}
    @{Name="payment-service"; Port=8400; CPU=512; Memory=1024}
    @{Name="shipping-service"; Port=8600; CPU=512; Memory=1024}
    @{Name="favourite-service"; Port=8800; CPU=512; Memory=1024}
    @{Name="proxy-client"; Port=8900; CPU=512; Memory=1024}
)

foreach ($service in $services) {
    Write-Host "`nCreating task definition: $($service.Name)" -ForegroundColor Yellow
    
    $taskDefFile = Join-Path $env:TEMP "$($service.Name)-taskdef.json"
    
    $taskDef = @{
        family                   = "$Environment-$($service.Name)"
        networkMode              = "awsvpc"
        requiresCompatibilities  = @("FARGATE")
        cpu                      = "$($service.CPU)"
        memory                   = "$($service.Memory)"
        executionRoleArn         = $executionRoleArn
        taskRoleArn              = $taskRoleArn
        containerDefinitions     = @(
            @{
                name      = $service.Name
                image     = "$DockerRegistry/$($service.Name):$ImageTag"
                essential = $true
                portMappings = @(
                    @{
                        containerPort = $service.Port
                        protocol      = "tcp"
                    }
                )
                environment = @(
                    @{name = "SPRING_PROFILES_ACTIVE"; value = $Environment}
                    @{name = "JAVA_OPTS"; value = "-Xmx512m -Xms256m -XX:+UseG1GC"}
                )
                logConfiguration = @{
                    logDriver = "awslogs"
                    options   = @{
                        "awslogs-group"         = "/ecs/$Environment-ecommerce"
                        "awslogs-region"        = "us-east-1"
                        "awslogs-stream-prefix" = $service.Name
                    }
                }
            }
        )
    }
    
    $taskDef | ConvertTo-Json -Depth 10 | Out-File -FilePath $taskDefFile -Encoding UTF8
    
    Write-Host "  Task definition file: $taskDefFile" -ForegroundColor Gray
    Write-Host "  Image: $DockerRegistry/$($service.Name):$ImageTag" -ForegroundColor Gray
    Write-Host "  Port: $($service.Port)" -ForegroundColor Gray
    Write-Host "  Resources: $($service.CPU) CPU, $($service.Memory) Memory" -ForegroundColor Gray
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Task Definitions Created!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                    Deployment Preparation Complete                           ║
╚══════════════════════════════════════════════════════════════════════════════╝

Next steps:
1. Review task definitions in: $env:TEMP
2. Register task definitions: aws ecs register-task-definition --cli-input-json file://taskdef.json
3. Create ECS services
4. Monitor deployment in AWS Console

Quick access:
- ECS Console: https://console.aws.amazon.com/ecs/
- CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/
- Load Balancer: http://$albDns

"@ -ForegroundColor Green

Write-Host "To manually register a task definition:" -ForegroundColor Cyan
Write-Host "aws ecs register-task-definition --cli-input-json file://$env:TEMP\service-discovery-taskdef.json" -ForegroundColor White
Write-Host ""
