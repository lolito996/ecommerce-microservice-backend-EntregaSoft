#!/usr/bin/env pwsh
# Deploy Terraform Environment
# Deploys infrastructure for dev, stage, or prod environment

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment,
    
    [switch]$AutoApprove,
    [switch]$Destroy,
    [switch]$Plan
)

$ErrorActionPreference = "Stop"

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                  Infrastructure Deployment Script                            ║
║                  E-Commerce Microservices Platform                           ║
╚══════════════════════════════════════════════════════════════════════════════╝

Environment: $Environment
Action:      $(if ($Destroy) { "DESTROY" } elseif ($Plan) { "PLAN" } else { "DEPLOY" })

"@ -ForegroundColor Cyan

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Terraform is not installed" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: AWS CLI is not installed" -ForegroundColor Red
    exit 1
}

# Verify AWS credentials
try {
    $identity = aws sts get-caller-identity | ConvertFrom-Json
    Write-Host "✓ AWS Account: $($identity.Account)" -ForegroundColor Green
    Write-Host "✓ AWS User: $($identity.Arn)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: AWS credentials not configured" -ForegroundColor Red
    exit 1
}

# Navigate to environment directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envDir = Join-Path $scriptDir ".." "aws-environments" $Environment

if (-not (Test-Path $envDir)) {
    Write-Host "ERROR: Environment directory not found: $envDir" -ForegroundColor Red
    exit 1
}

Set-Location $envDir
Write-Host "`nWorking directory: $envDir" -ForegroundColor Cyan

# Check if backend is configured
$mainTf = Get-Content (Join-Path $envDir "main.tf") -Raw
if ($mainTf -match '# bucket\s+=') {
    Write-Host "`n⚠️  WARNING: Backend configuration is commented out!" -ForegroundColor Red
    Write-Host "Run init-backend.ps1 first and update the backend configuration" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y") {
        exit 0
    }
}

# Initialize Terraform
Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
terraform init -upgrade
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform init failed" -ForegroundColor Red
    exit 1
}

# Validate
Write-Host "`nValidating configuration..." -ForegroundColor Yellow
terraform validate
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform validation failed" -ForegroundColor Red
    exit 1
}

# Format check
Write-Host "`nChecking formatting..." -ForegroundColor Yellow
terraform fmt -check -recursive
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Some files need formatting. Run: terraform fmt -recursive" -ForegroundColor Yellow
}

if ($Destroy) {
    Write-Host "`n⚠️  WARNING: This will DESTROY all infrastructure in $Environment!" -ForegroundColor Red
    
    if ($Environment -eq "prod") {
        Write-Host "⚠️  PRODUCTION ENVIRONMENT - Extra caution required!" -ForegroundColor Red
    }
    
    if (-not $AutoApprove) {
        Write-Host "`nType the environment name '$Environment' to confirm destruction:" -ForegroundColor Yellow
        $confirmation = Read-Host
        if ($confirmation -ne $Environment) {
            Write-Host "Destruction cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host "`nDestroying infrastructure..." -ForegroundColor Red
    if ($AutoApprove) {
        terraform destroy -auto-approve
    } else {
        terraform destroy
    }
    
    exit $LASTEXITCODE
}

# Plan
Write-Host "`nGenerating execution plan..." -ForegroundColor Yellow
$planFile = "$Environment.tfplan"
terraform plan -out="$planFile"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform plan failed" -ForegroundColor Red
    exit 1
}

if ($Plan) {
    Write-Host "`nPlan saved to: $planFile" -ForegroundColor Green
    Write-Host "To apply, run: terraform apply `"$planFile`"" -ForegroundColor Cyan
    exit 0
}

# Cost estimation (if infracost is available)
if (Get-Command infracost -ErrorAction SilentlyContinue) {
    Write-Host "`nEstimating costs..." -ForegroundColor Yellow
    infracost breakdown --path . --terraform-plan-flags "-out=`"$planFile`""
}

# Apply
Write-Host "`nApplying infrastructure changes..." -ForegroundColor Yellow

if ($Environment -eq "prod" -and -not $AutoApprove) {
    Write-Host "⚠️  PRODUCTION DEPLOYMENT" -ForegroundColor Red
    Write-Host "Please review the plan carefully." -ForegroundColor Yellow
    $continue = Read-Host "Continue with deployment? (yes/no)"
    if ($continue -ne "yes") {
        Write-Host "Deployment cancelled" -ForegroundColor Yellow
        exit 0
    }
}

if ($AutoApprove) {
    terraform apply -auto-approve "$planFile"
} else {
    terraform apply "$planFile"
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform apply failed" -ForegroundColor Red
    exit 1
}

# Show outputs
Write-Host "`n" -NoNewline
terraform output environment_summary

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                    Deployment Completed Successfully!                        ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

# Save important outputs
$outputFile = Join-Path $envDir "deployment-info.json"
$outputs = @{
    environment = $Environment
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    vpc_id = (terraform output -raw vpc_id)
    alb_dns = (terraform output -raw alb_dns_name)
    ecs_cluster = (terraform output -raw ecs_cluster_name)
}

$outputs | ConvertTo-Json | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "Deployment info saved to: $outputFile" -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Build and push Docker images to ECR" -ForegroundColor White
Write-Host "2. Create ECS Task Definitions" -ForegroundColor White
Write-Host "3. Create ECS Services" -ForegroundColor White
Write-Host "4. Configure Route 53 (if using custom domain)" -ForegroundColor White
Write-Host ""

Write-Host "Quick access URLs:" -ForegroundColor Cyan
$albDns = terraform output -raw alb_dns_name
Write-Host "  API Gateway:  http://$albDns/api" -ForegroundColor White
Write-Host "  Eureka:       http://${albDns}:8761" -ForegroundColor White
Write-Host "  Prometheus:   http://${albDns}:9090" -ForegroundColor White
Write-Host "  Grafana:      http://${albDns}:3000" -ForegroundColor White
Write-Host ""
