#!/usr/bin/env pwsh
# Check ECS Services Health and Test Endpoints
# Verifies deployment status and tests API endpoints

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment
)

$ErrorActionPreference = "Stop"

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                    ECS Services Health Check                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝

Environment: $Environment

"@ -ForegroundColor Cyan

# Get infrastructure details
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envDir = Join-Path $scriptDir ".." "aws-environments" $Environment

Push-Location $envDir
try {
    $clusterName = terraform output -raw ecs_cluster_name
    $albDns = terraform output -raw alb_dns_name
} finally {
    Pop-Location
}

Write-Host "Cluster: $clusterName" -ForegroundColor Gray
Write-Host "ALB DNS: $albDns`n" -ForegroundColor Gray

# List of services to check
$services = @(
    "dev-service-discovery"
    "dev-cloud-config"
    "dev-api-gateway"
    "dev-user-service"
    "dev-product-service"
    "dev-order-service"
    "dev-payment-service"
    "dev-shipping-service"
    "dev-favourite-service"
    "dev-proxy-client"
)

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Service Status" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$healthyServices = 0
$unhealthyServices = 0

foreach ($serviceName in $services) {
    Write-Host "`n$serviceName" -ForegroundColor Yellow
    
    try {
        $serviceInfo = aws ecs describe-services `
            --cluster $clusterName `
            --services $serviceName `
            --query 'services[0]' `
            2>&1 | ConvertFrom-Json
        
        if ($serviceInfo) {
            $desiredCount = $serviceInfo.desiredCount
            $runningCount = $serviceInfo.runningCount
            $pendingCount = $serviceInfo.pendingCount
            $status = $serviceInfo.status
            
            Write-Host "  Status: $status" -ForegroundColor $(if ($status -eq "ACTIVE") { "Green" } else { "Red" })
            Write-Host "  Desired: $desiredCount | Running: $runningCount | Pending: $pendingCount" -ForegroundColor Gray
            
            if ($runningCount -eq $desiredCount -and $status -eq "ACTIVE") {
                Write-Host "  ✓ Healthy" -ForegroundColor Green
                $healthyServices++
            } else {
                Write-Host "  ⚠ Not Ready" -ForegroundColor Yellow
                $unhealthyServices++
                
                # Show recent events
                if ($serviceInfo.events -and $serviceInfo.events.Count -gt 0) {
                    $latestEvent = $serviceInfo.events[0]
                    Write-Host "  Latest event: $($latestEvent.message)" -ForegroundColor Gray
                }
            }
        }
    } catch {
        Write-Host "  ✗ Error checking service" -ForegroundColor Red
        $unhealthyServices++
    }
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "`nHealthy Services: $healthyServices / $($services.Count)" -ForegroundColor $(if ($healthyServices -eq $services.Count) { "Green" } else { "Yellow" })
Write-Host "Unhealthy Services: $unhealthyServices" -ForegroundColor $(if ($unhealthyServices -eq 0) { "Green" } else { "Red" })

# Test API endpoints if services are healthy
if ($healthyServices -ge 3) {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Testing API Endpoints" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    $baseUrl = "http://$albDns"
    
    $endpoints = @(
        @{Name="API Gateway Health"; Url="$baseUrl/api/actuator/health"; Method="GET"}
        @{Name="Service Discovery (Eureka)"; Url="http://$albDns:8761"; Method="GET"}
        @{Name="Products API"; Url="$baseUrl/api/products"; Method="GET"}
        @{Name="Users API"; Url="$baseUrl/api/users"; Method="GET"}
        @{Name="Orders API"; Url="$baseUrl/api/orders"; Method="GET"}
    )
    
    foreach ($endpoint in $endpoints) {
        Write-Host "`nTesting: $($endpoint.Name)" -ForegroundColor Yellow
        Write-Host "  URL: $($endpoint.Url)" -ForegroundColor Gray
        
        try {
            $response = Invoke-WebRequest -Uri $endpoint.Url -Method $endpoint.Method -TimeoutSec 10 -ErrorAction Stop
            $statusCode = $response.StatusCode
            
            if ($statusCode -ge 200 -and $statusCode -lt 300) {
                Write-Host "  ✓ Success ($statusCode)" -ForegroundColor Green
            } else {
                Write-Host "  ⚠ Unexpected status ($statusCode)" -ForegroundColor Yellow
            }
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.Value__
            if ($statusCode) {
                Write-Host "  ✗ Failed ($statusCode)" -ForegroundColor Red
            } else {
                Write-Host "  ✗ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Quick Commands" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host @"

View service logs:
  aws logs tail /ecs/$Environment-ecommerce --follow --since 10m

Describe specific service:
  aws ecs describe-services --cluster $clusterName --services dev-api-gateway

List running tasks:
  aws ecs list-tasks --cluster $clusterName --service-name dev-api-gateway

View task details:
  aws ecs describe-tasks --cluster $clusterName --tasks <task-id>

Access URLs:
  API Gateway: http://$albDns/api
  Eureka Dashboard: http://$albDns:8761
  
ECS Console:
  https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/$clusterName/services

"@ -ForegroundColor Gray

Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    Health Check Complete                                    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
