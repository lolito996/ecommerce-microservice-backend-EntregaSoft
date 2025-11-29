#!/usr/bin/env pwsh
# Initialize Terraform Backend Infrastructure
# This script creates the S3 bucket and DynamoDB table for remote state management
# Run this FIRST before deploying any environment

param(
    [switch]$AutoApprove,
    [switch]$Destroy
)

$ErrorActionPreference = "Stop"

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                   Terraform Backend Initialization                           ║
║                   E-Commerce Microservices Platform                          ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Terraform
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Terraform is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Install from: https://www.terraform.io/downloads" -ForegroundColor Yellow
    exit 1
}

$tfVersion = terraform version -json | ConvertFrom-Json
Write-Host "✓ Terraform version: $($tfVersion.terraform_version)" -ForegroundColor Green

# Check AWS CLI
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: AWS CLI is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check AWS credentials
try {
    $identity = aws sts get-caller-identity | ConvertFrom-Json
    Write-Host "✓ AWS Account: $($identity.Account)" -ForegroundColor Green
    Write-Host "✓ AWS User: $($identity.Arn)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: AWS credentials not configured" -ForegroundColor Red
    Write-Host "Run: aws configure" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Navigate to backend bootstrap directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $scriptDir ".." "aws-backend-bootstrap"

if (-not (Test-Path $backendDir)) {
    Write-Host "ERROR: Backend bootstrap directory not found: $backendDir" -ForegroundColor Red
    exit 1
}

Set-Location $backendDir
Write-Host "Working directory: $backendDir" -ForegroundColor Cyan

# Initialize Terraform
Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform init failed" -ForegroundColor Red
    exit 1
}

if ($Destroy) {
    Write-Host "`n⚠️  WARNING: This will DESTROY the Terraform backend!" -ForegroundColor Red
    Write-Host "This will delete the S3 bucket and DynamoDB table." -ForegroundColor Red
    Write-Host "Make sure all environments are destroyed first!" -ForegroundColor Yellow
    
    if (-not $AutoApprove) {
        $confirmation = Read-Host "Type 'destroy' to confirm"
        if ($confirmation -ne "destroy") {
            Write-Host "Destruction cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    
    terraform destroy -auto-approve
    exit $LASTEXITCODE
}

# Plan
Write-Host "`nGenerating execution plan..." -ForegroundColor Yellow
terraform plan -out="backend.tfplan"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform plan failed" -ForegroundColor Red
    exit 1
}

# Apply
Write-Host "`nApplying infrastructure changes..." -ForegroundColor Yellow
if ($AutoApprove) {
    terraform apply -auto-approve "backend.tfplan"
} else {
    terraform apply "backend.tfplan"
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform apply failed" -ForegroundColor Red
    exit 1
}

# Get outputs
Write-Host "`n" -NoNewline
terraform output -raw instructions

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                         Backend Setup Complete!                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

# Save backend configuration to file
$bucketName = terraform output -raw s3_bucket_name
$tableName = terraform output -raw dynamodb_table_name

$backendConfig = @"
# Backend Configuration
# Copy this to your environment's main.tf file

terraform {
  backend "s3" {
    bucket         = "$bucketName"
    key            = "<environment>/terraform.tfstate"  # Change per environment
    region         = "us-east-1"
    dynamodb_table = "$tableName"
    encrypt        = true
  }
}

# Environment keys:
# - dev:   key = "dev/terraform.tfstate"
# - stage: key = "stage/terraform.tfstate"
# - prod:  key = "prod/terraform.tfstate"
"@

$configFile = Join-Path $backendDir "backend-config-generated.txt"
$backendConfig | Out-File -FilePath $configFile -Encoding UTF8

Write-Host "Backend configuration saved to: $configFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update backend configuration in each environment" -ForegroundColor White
Write-Host "2. Run: .\scripts\deploy-environment.ps1 -Environment dev" -ForegroundColor White
Write-Host ""
