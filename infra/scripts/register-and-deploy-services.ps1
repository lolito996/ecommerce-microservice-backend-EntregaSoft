#!/usr/bin/env pwsh
# Register ECS Task Definitions and Create Services
# Automatically registers all task definitions and creates ECS services

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment,
    
    [switch]$RegisterOnly,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║              Register Task Definitions and Create Services                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

Environment: $Environment

"@ -ForegroundColor Cyan

# Get infrastructure details
Write-Host "Retrieving infrastructure details..." -ForegroundColor Yellow
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envDir = Join-Path $scriptDir ".." "aws-environments" $Environment

Push-Location $envDir
try {
    $clusterName = terraform output -raw ecs_cluster_name
    $vpcId = terraform output -raw vpc_id
    $albDns = terraform output -raw alb_dns_name
    $apiGatewayTgArn = terraform output -raw api_gateway_target_group_arn
    
    # Get subnet and security group info from Terraform state
    $stateJson = terraform show -json | ConvertFrom-Json
    $privateSubnets = @()
    $ecsSecurityGroup = ""
    
    foreach ($resource in $stateJson.values.root_module.child_modules) {
        if ($resource.address -eq "module.vpc") {
            $privateSubnets = ($resource.resources | Where-Object { $_.type -eq "aws_subnet" -and $_.values.tags.Type -eq "private" }).values.id
        }
        if ($resource.address -eq "module.security_groups") {
            $sgResource = $resource.resources | Where-Object { $_.type -eq "aws_security_group" -and $_.name -eq "ecs_tasks" }
            if ($sgResource) {
                $ecsSecurityGroup = $sgResource.values.id
            }
        }
    }
    
    Write-Host "✓ Cluster: $clusterName" -ForegroundColor Green
    Write-Host "✓ VPC: $vpcId" -ForegroundColor Green
    Write-Host "✓ Private Subnets: $($privateSubnets.Count) found" -ForegroundColor Green
    Write-Host "✓ Security Group: $ecsSecurityGroup" -ForegroundColor Green
    
} finally {
    Pop-Location
}

$services = @(
    @{Name="service-discovery"; Port=8761; DesiredCount=1; TargetGroup=$null}
    @{Name="cloud-config"; Port=9296; DesiredCount=1; TargetGroup=$null}
    @{Name="api-gateway"; Port=8080; DesiredCount=2; TargetGroup=$apiGatewayTgArn}
    @{Name="user-service"; Port=8700; DesiredCount=2; TargetGroup=$null}
    @{Name="product-service"; Port=8500; DesiredCount=2; TargetGroup=$null}
    @{Name="order-service"; Port=8300; DesiredCount=2; TargetGroup=$null}
    @{Name="payment-service"; Port=8400; DesiredCount=2; TargetGroup=$null}
    @{Name="shipping-service"; Port=8600; DesiredCount=2; TargetGroup=$null}
    @{Name="favourite-service"; Port=8800; DesiredCount=2; TargetGroup=$null}
    @{Name="proxy-client"; Port=8900; DesiredCount=2; TargetGroup=$null}
)

$registered = @()
$failed = @()

# Register Task Definitions
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Registering Task Definitions" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

foreach ($service in $services) {
    Write-Host "`nRegistering: $($service.Name)" -ForegroundColor Yellow
    
    $taskDefFile = Join-Path $env:TEMP "$($service.Name)-taskdef.json"
    
    if (-not (Test-Path $taskDefFile)) {
        Write-Host "  ✗ Task definition file not found: $taskDefFile" -ForegroundColor Red
        $failed += $service.Name
        continue
    }
    
    try {
        # Read the JSON content and pass it via stdin or use proper file URI
        $result = aws ecs register-task-definition --cli-input-json ("file://" + $taskDefFile.Replace('\', '/')) 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $resultJson = $result | ConvertFrom-Json
            $revision = $resultJson.taskDefinition.revision
            Write-Host "  ✓ Registered: $($service.Name):$revision" -ForegroundColor Green
            $registered += @{
                Name = $service.Name
                Revision = $revision
                TargetGroup = $service.TargetGroup
                Port = $service.Port
                DesiredCount = $service.DesiredCount
            }
        } else {
            Write-Host "  ✗ Failed to register" -ForegroundColor Red
            Write-Host "  Error output: $($result -join "`n")" -ForegroundColor Red
            $failed += $service.Name
        }
    } catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
        $failed += $service.Name
    }
}

if ($RegisterOnly) {
    Write-Host "`n✅ Task definitions registered!" -ForegroundColor Green
    Write-Host "Run without -RegisterOnly to create services" -ForegroundColor Cyan
    exit 0
}

# Create ECS Services
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Creating ECS Services" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$servicesCreated = @()

foreach ($service in $registered) {
    Write-Host "`nCreating service: $($service.Name)" -ForegroundColor Yellow
    
    $serviceName = "$Environment-$($service.Name)"
    $taskDef = "$Environment-$($service.Name):$($service.Revision)"
    
    # Check if service already exists
    $existing = aws ecs describe-services --cluster $clusterName --services $serviceName 2>$null | ConvertFrom-Json
    
    if ($existing.services -and $existing.services[0].status -ne "INACTIVE") {
        if ($Force) {
            Write-Host "  ⚠️  Service exists, updating..." -ForegroundColor Yellow
            
            $updateCmd = "aws ecs update-service --cluster $clusterName --service $serviceName --task-definition $taskDef --desired-count $($service.DesiredCount)"
            Invoke-Expression $updateCmd | Out-Null
            
            Write-Host "  ✓ Service updated" -ForegroundColor Green
            $servicesCreated += $service.Name
        } else {
            Write-Host "  ⊘ Service already exists (use -Force to update)" -ForegroundColor Gray
        }
        continue
    }
    
    # Build service creation command
    $networkConfig = @{
        awsvpcConfiguration = @{
            subnets = $privateSubnets
            securityGroups = @($ecsSecurityGroup)
            assignPublicIp = "DISABLED"
        }
    } | ConvertTo-Json -Compress -Depth 10
    
    $createCmd = "aws ecs create-service --cluster $clusterName --service-name $serviceName --task-definition $taskDef --desired-count $($service.DesiredCount) --launch-type FARGATE --network-configuration '$networkConfig'"
    
    # Add load balancer if target group exists
    if ($service.TargetGroup) {
        $lbConfig = @{
            targetGroupArn = $service.TargetGroup
            containerName = $service.Name
            containerPort = $service.Port
        } | ConvertTo-Json -Compress
        
        $createCmd += " --load-balancers '$lbConfig'"
    }
    
    try {
        Invoke-Expression $createCmd | Out-Null
        Write-Host "  ✓ Service created" -ForegroundColor Green
        $servicesCreated += $service.Name
    } catch {
        Write-Host "  ✗ Failed to create service: $_" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`nTask Definitions Registered: $($registered.Count)" -ForegroundColor Green
Write-Host "Services Created: $($servicesCreated.Count)" -ForegroundColor Green
if ($failed.Count -gt 0) {
    Write-Host "Failed: $($failed.Count) - $($failed -join ', ')" -ForegroundColor Red
}

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                    Deployment Complete!                                      ║
╚══════════════════════════════════════════════════════════════════════════════╝

Your microservices are now deploying to ECS!

Monitor deployment:
  aws ecs list-services --cluster $clusterName
  aws ecs describe-services --cluster $clusterName --services $Environment-api-gateway

View logs:
  aws logs tail /ecs/$Environment-ecommerce --follow

Access your services:
  API Gateway: http://$albDns/api
  Eureka: http://${albDns}:8761

ECS Console:
  https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/$clusterName/services

"@ -ForegroundColor Green
