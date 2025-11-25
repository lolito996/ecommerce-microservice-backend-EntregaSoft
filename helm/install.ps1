# Script de instalación de Helm Chart para Ecommerce Microservices
# Uso: .\helm\install.ps1 -Environment dev -Namespace default

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "default",
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "ecommerce-app",
    
    [Parameter(Mandatory=$false)]
    [string]$Registry = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "latest",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Upgrade = $false
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Instalación de Ecommerce Microservices" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar Helm
Write-Host "Verificando Helm..." -ForegroundColor Yellow
try {
    $helmVersion = helm version --short
    Write-Host "✓ Helm instalado: $helmVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Helm no está instalado. Por favor instala Helm 3.x" -ForegroundColor Red
    exit 1
}

# Verificar kubectl
Write-Host "Verificando kubectl..." -ForegroundColor Yellow
try {
    $kubectlVersion = kubectl version --client --short
    Write-Host "✓ kubectl disponible: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ kubectl no está disponible" -ForegroundColor Red
    exit 1
}

# Verificar conexión al cluster
Write-Host "Verificando conexión al cluster..." -ForegroundColor Yellow
try {
    kubectl cluster-info | Out-Null
    Write-Host "✓ Conectado al cluster de Kubernetes" -ForegroundColor Green
} catch {
    Write-Host "✗ No se puede conectar al cluster. Verifica tu configuración de kubectl" -ForegroundColor Red
    exit 1
}

# Verificar que el chart existe
$chartPath = ".\helm\ecommerce-microservices"
if (-not (Test-Path $chartPath)) {
    Write-Host "✗ No se encuentra el chart en: $chartPath" -ForegroundColor Red
    exit 1
}

# Validar el chart
Write-Host "Validando el chart..." -ForegroundColor Yellow
$lintResult = helm lint $chartPath 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ El chart tiene errores:" -ForegroundColor Red
    Write-Host $lintResult
    exit 1
}
Write-Host "✓ Chart válido" -ForegroundColor Green

# Determinar archivo de valores
$valuesFile = ".\helm\ecommerce-microservices\values-$Environment.yaml"
if (-not (Test-Path $valuesFile)) {
    Write-Host "⚠ Archivo de valores no encontrado: $valuesFile" -ForegroundColor Yellow
    Write-Host "Usando values.yaml por defecto" -ForegroundColor Yellow
    $valuesFile = ".\helm\ecommerce-microservices\values.yaml"
}

# Crear namespace si no existe
Write-Host "Verificando namespace '$Namespace'..." -ForegroundColor Yellow
$namespaceExists = kubectl get namespace $Namespace 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creando namespace '$Namespace'..." -ForegroundColor Yellow
    kubectl create namespace $Namespace
    Write-Host "✓ Namespace creado" -ForegroundColor Green
} else {
    Write-Host "✓ Namespace existe" -ForegroundColor Green
}

# Preparar comando de Helm
$helmCommand = if ($Upgrade) { "upgrade" } else { "install" }
$helmArgs = @(
    $helmCommand,
    $ReleaseName,
    $chartPath,
    "--namespace", $Namespace,
    "-f", $valuesFile
)

# Agregar valores adicionales si se proporcionan
if ($Registry) {
    $helmArgs += "--set", "global.registry=$Registry"
}
if ($ImageTag) {
    $helmArgs += "--set", "global.imageTag=$ImageTag"
}

# Agregar dry-run si se solicita
if ($DryRun) {
    $helmArgs += "--dry-run", "--debug"
    Write-Host ""
    Write-Host "=== DRY RUN MODE ===" -ForegroundColor Cyan
    Write-Host "No se realizarán cambios reales" -ForegroundColor Cyan
    Write-Host ""
}

# Ejecutar Helm
Write-Host ""
Write-Host "Ejecutando: helm $($helmArgs -join ' ')" -ForegroundColor Cyan
Write-Host ""

try {
    if ($DryRun) {
        helm @helmArgs
    } else {
        helm @helmArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "✓ Instalación completada exitosamente!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Comandos útiles:" -ForegroundColor Cyan
            Write-Host "  Ver estado:     helm status $ReleaseName --namespace $Namespace" -ForegroundColor White
            Write-Host "  Ver recursos:    kubectl get all --namespace $Namespace" -ForegroundColor White
            Write-Host "  Ver logs:        kubectl logs -l app=<service-name> --namespace $Namespace" -ForegroundColor White
            Write-Host "  Desinstalar:     helm uninstall $ReleaseName --namespace $Namespace" -ForegroundColor White
        } else {
            Write-Host ""
            Write-Host "✗ Error durante la instalación" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host ""
    Write-Host "✗ Error: $_" -ForegroundColor Red
    exit 1
}

