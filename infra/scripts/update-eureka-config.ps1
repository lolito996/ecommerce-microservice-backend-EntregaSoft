#!/usr/bin/env pwsh
# Update Microservices with Eureka Configuration
# Configures environment variables for Eureka service discovery

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment
)

$ErrorActionPreference = "Stop"

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║           Update Microservices with Eureka Configuration                    ║
╚══════════════════════════════════════════════════════════════════════════════╝

Environment: $Environment

"@ -ForegroundColor Cyan

# Get cluster name
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envDir = Join-Path $scriptDir ".." "aws-environments" $Environment

Push-Location $envDir
try {
    $clusterName = terraform output -raw ecs_cluster_name
    $vpcId = terraform output -raw vpc_id
} finally {
    Pop-Location
}

Write-Host "Cluster: $clusterName" -ForegroundColor Gray
Write-Host "VPC: $vpcId`n" -ForegroundColor Gray

# Get Eureka service task IP
Write-Host "Getting Eureka service IP..." -ForegroundColor Yellow
$eurekaTaskArn = aws ecs list-tasks --cluster $clusterName --service-name "$Environment-service-discovery" --query 'taskArns[0]' --output text

if (-not $eurekaTaskArn -or $eurekaTaskArn -eq "None") {
    Write-Host "✗ Could not find Eureka service task" -ForegroundColor Red
    exit 1
}

$eurekaIp = aws ecs describe-tasks --cluster $clusterName --tasks $eurekaTaskArn --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address' --output text

Write-Host "✓ Eureka IP: $eurekaIp" -ForegroundColor Green

# Eureka URL
$eurekaUrl = "http://${eurekaIp}:8761/eureka/"
Write-Host "✓ Eureka URL: $eurekaUrl`n" -ForegroundColor Green

# Services to update (excluding service-discovery itself)
$services = @(
    "cloud-config"
    "api-gateway"
    "user-service"
    "product-service"
    "order-service"
    "payment-service"
    "shipping-service"
    "favourite-service"
    "proxy-client"
)

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Updating Task Definitions" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$updated = 0
$failed = 0

foreach ($serviceName in $services) {
    Write-Host "`nUpdating: $serviceName" -ForegroundColor Yellow
    
    # Get current task definition
    $taskDefArn = aws ecs describe-services --cluster $clusterName --services "$Environment-$serviceName" --query 'services[0].taskDefinition' --output text
    
    if (-not $taskDefArn -or $taskDefArn -eq "None") {
        Write-Host "  ✗ Service not found" -ForegroundColor Red
        $failed++
        continue
    }
    
    # Get task definition details
    $taskDef = aws ecs describe-task-definition --task-definition $taskDefArn | ConvertFrom-Json
    
    # Update environment variables
    $container = $taskDef.taskDefinition.containerDefinitions[0]
    
    # Define environment variables to add/update
    $envVarsToSet = @{
        "EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE" = $eurekaUrl
        "EUREKA_INSTANCE_PREFER_IP_ADDRESS" = "true"
        "SPRING_CLOUD_INETUTILS_PREFERRED_NETWORKS" = "10.0"
    }
    
    # Get current environment variables
    $envVars = $container.environment
    
    # Update or add each variable
    foreach ($varName in $envVarsToSet.Keys) {
        $varValue = $envVarsToSet[$varName]
        $exists = $false
        
        for ($i = 0; $i -lt $envVars.Count; $i++) {
            if ($envVars[$i].name -eq $varName) {
                $envVars[$i].value = $varValue
                $exists = $true
                break
            }
        }
        
        if (-not $exists) {
            $envVars += @{name = $varName; value = $varValue}
        }
    }
    
    $container.environment = $envVars
    
    # Create new task definition JSON
    $newTaskDef = @{
        family                   = $taskDef.taskDefinition.family
        networkMode              = $taskDef.taskDefinition.networkMode
        requiresCompatibilities  = $taskDef.taskDefinition.requiresCompatibilities
        cpu                      = $taskDef.taskDefinition.cpu
        memory                   = $taskDef.taskDefinition.memory
        executionRoleArn         = $taskDef.taskDefinition.executionRoleArn
        taskRoleArn              = $taskDef.taskDefinition.taskRoleArn
        containerDefinitions     = @($container)
    }
    
    $taskDefFile = Join-Path $env:TEMP "$serviceName-taskdef-updated.json"
    $newTaskDef | ConvertTo-Json -Depth 10 | Out-File -FilePath $taskDefFile -Encoding UTF8
    
    # Register new task definition
    try {
        $result = aws ecs register-task-definition --cli-input-json ("file://" + $taskDefFile.Replace('\', '/')) 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $resultJson = $result | ConvertFrom-Json
            $revision = $resultJson.taskDefinition.revision
            Write-Host "  ✓ Registered: ${serviceName}:${revision}" -ForegroundColor Green
            
            # Update service to use new task definition
            $updateResult = aws ecs update-service --cluster $clusterName --service "$Environment-$serviceName" --task-definition "$($taskDef.taskDefinition.family):$revision" --force-new-deployment 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Service updated with new configuration" -ForegroundColor Green
                $updated++
            } else {
                Write-Host "  ✗ Failed to update service" -ForegroundColor Red
                $failed++
            }
        } else {
            Write-Host "  ✗ Failed to register task definition" -ForegroundColor Red
            Write-Host "  Error: $($result -join "`n")" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Update Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`nUpdated: $updated" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

Write-Host "`n╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    Configuration Update Complete                            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host @"

Services are redeploying with new Eureka configuration.
This will take 2-3 minutes.

Monitor deployment:
  cd ..\..\scripts
  .\check-services-health.ps1 -Environment $Environment

"@ -ForegroundColor Gray
