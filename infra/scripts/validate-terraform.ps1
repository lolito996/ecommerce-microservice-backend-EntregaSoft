#!/usr/bin/env pwsh
# Validate Terraform Configuration
# Runs validation, security checks, and linting

param(
    [ValidateSet("all", "dev", "stage", "prod", "backend")]
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║              Terraform Configuration Validation                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$infraDir = Join-Path $scriptDir ".."

$results = @{
    passed = 0
    failed = 0
    warnings = 0
}

function Test-TerraformDirectory {
    param([string]$Path, [string]$Name)
    
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Testing: $Name" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    if (-not (Test-Path $Path)) {
        Write-Host "✗ Directory not found: $Path" -ForegroundColor Red
        $script:results.failed++
        return
    }
    
    Push-Location $Path
    
    try {
        # Terraform fmt
        Write-Host "`n[1/4] Checking formatting..." -ForegroundColor Yellow
        terraform fmt -check -recursive
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Formatting is correct" -ForegroundColor Green
            $script:results.passed++
        } else {
            Write-Host "⚠ Some files need formatting" -ForegroundColor Yellow
            $script:results.warnings++
        }
        
        # Terraform init
        Write-Host "`n[2/4] Initializing..." -ForegroundColor Yellow
        terraform init -backend=false -upgrade > $null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Initialization successful" -ForegroundColor Green
            $script:results.passed++
        } else {
            Write-Host "✗ Initialization failed" -ForegroundColor Red
            $script:results.failed++
            return
        }
        
        # Terraform validate
        Write-Host "`n[3/4] Validating configuration..." -ForegroundColor Yellow
        terraform validate
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Configuration is valid" -ForegroundColor Green
            $script:results.passed++
        } else {
            Write-Host "✗ Validation failed" -ForegroundColor Red
            $script:results.failed++
        }
        
        # TFLint (if available)
        Write-Host "`n[4/4] Running TFLint..." -ForegroundColor Yellow
        if (Get-Command tflint -ErrorAction SilentlyContinue) {
            tflint --init > $null 2>&1
            tflint
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ TFLint passed" -ForegroundColor Green
                $script:results.passed++
            } else {
                Write-Host "⚠ TFLint found issues" -ForegroundColor Yellow
                $script:results.warnings++
            }
        } else {
            Write-Host "⊘ TFLint not installed (optional)" -ForegroundColor Gray
        }
        
    } finally {
        Pop-Location
    }
}

# Test targets
$targets = @()

switch ($Target) {
    "all" {
        $targets = @(
            @{ Name = "Backend Bootstrap"; Path = Join-Path $infraDir "aws-backend-bootstrap" }
            @{ Name = "Dev Environment"; Path = Join-Path $infraDir "aws-environments" "dev" }
            @{ Name = "Stage Environment"; Path = Join-Path $infraDir "aws-environments" "stage" }
            @{ Name = "Prod Environment"; Path = Join-Path $infraDir "aws-environments" "prod" }
        )
    }
    "backend" {
        $targets = @(
            @{ Name = "Backend Bootstrap"; Path = Join-Path $infraDir "aws-backend-bootstrap" }
        )
    }
    default {
        $targets = @(
            @{ Name = "$Target Environment"; Path = Join-Path $infraDir "aws-environments" $Target }
        )
    }
}

# Run tests
foreach ($target in $targets) {
    Test-TerraformDirectory -Path $target.Path -Name $target.Name
}

# Summary
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`nResults:" -ForegroundColor White
Write-Host "  ✓ Passed:   $($results.passed)" -ForegroundColor Green
Write-Host "  ⚠ Warnings: $($results.warnings)" -ForegroundColor Yellow
Write-Host "  ✗ Failed:   $($results.failed)" -ForegroundColor $(if ($results.failed -gt 0) { "Red" } else { "Green" })

if ($results.failed -gt 0) {
    Write-Host "`n❌ Validation failed!" -ForegroundColor Red
    exit 1
} elseif ($results.warnings -gt 0) {
    Write-Host "`n⚠️  Validation passed with warnings" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n✅ All validations passed!" -ForegroundColor Green
    exit 0
}
