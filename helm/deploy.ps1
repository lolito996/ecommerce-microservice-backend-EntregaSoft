# Script completo de despliegue con Helm
# Uso: .\helm\deploy.ps1 -Environment dev -BuildImages -LoadToKind

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "default",
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "ecommerce-app",
    
    [Parameter(Mandatory=$false)]
    [switch]$BuildImages = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$LoadToKind = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SetupCluster = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDeploy = $false
)

$ErrorActionPreference = "Stop"
$services = @(
    "service-discovery",
    "cloud-config",
    "api-gateway",
    "user-service",
    "product-service",
    "order-service",
    "payment-service",
    "shipping-service",
    "favourite-service",
    "proxy-client"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Despliegue de Ecommerce Microservices" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Paso 1: Configurar Cluster
if ($SetupCluster) {
    Write-Host "=== Paso 1: Configurando Cluster ===" -ForegroundColor Yellow
    if (Get-Command kind -ErrorAction SilentlyContinue) {
        $clusterExists = kind get clusters 2>&1 | Select-String "ecommerce-cluster"
        if (-not $clusterExists) {
            Write-Host "Creando cluster Kind..." -ForegroundColor Cyan
            kind create cluster --config kind.yml --name ecommerce-cluster
        } else {
            Write-Host "✓ Cluster Kind ya existe" -ForegroundColor Green
        }
        
        $KUBECONFIG_PATH = "$env:USERPROFILE\.kube\kind-ecommerce-cluster-config"
        kind get kubeconfig --name ecommerce-cluster > $KUBECONFIG_PATH
        $env:KUBECONFIG = $KUBECONFIG_PATH
        Write-Host "✓ Kubeconfig configurado" -ForegroundColor Green
    } else {
        Write-Host "⚠ Kind no está instalado. Asumiendo que el cluster ya está configurado." -ForegroundColor Yellow
    }
}

# Verificar conexión al cluster
Write-Host "Verificando conexión al cluster..." -ForegroundColor Yellow
try {
    kubectl cluster-info | Out-Null
    Write-Host "✓ Conectado al cluster" -ForegroundColor Green
} catch {
    Write-Host "✗ No se puede conectar al cluster" -ForegroundColor Red
    Write-Host "Ejecuta: .\helm\deploy.ps1 -SetupCluster" -ForegroundColor Yellow
    exit 1
}

# Paso 2: Construir Imágenes
if ($BuildImages) {
    Write-Host ""
    Write-Host "=== Paso 2: Construyendo Imágenes Docker ===" -ForegroundColor Yellow
    
    # Configurar JAVA_HOME si no está configurado
    if (-not $env:JAVA_HOME) {
        $javaPath = "C:\Program Files\Java\jdk-17"
        if (Test-Path $javaPath) {
            $env:JAVA_HOME = $javaPath
            Write-Host "✓ JAVA_HOME configurado: $javaPath" -ForegroundColor Green
        } else {
            Write-Host "⚠ JAVA_HOME no configurado. Asegúrate de tener Java instalado." -ForegroundColor Yellow
        }
    }
    
    $rootDir = Get-Location
    foreach ($service in $services) {
        Write-Host "Construyendo $service..." -ForegroundColor Cyan
        $servicePath = Join-Path $rootDir $service
        if (Test-Path $servicePath) {
            Set-Location $servicePath
            Write-Host "  Compilando..." -ForegroundColor Gray
            .\mvnw.cmd clean package -DskipTests 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Construyendo imagen Docker..." -ForegroundColor Gray
                docker build -t "$service`:latest" . 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ $service construido exitosamente" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ Error construyendo imagen de $service" -ForegroundColor Red
                }
            } else {
                Write-Host "  ✗ Error compilando $service" -ForegroundColor Red
            }
            Set-Location $rootDir
        } else {
            Write-Host "  ⚠ Directorio $service no encontrado" -ForegroundColor Yellow
        }
    }
}

# Paso 3: Cargar Imágenes en Kind
if ($LoadToKind) {
    Write-Host ""
    Write-Host "=== Paso 3: Cargando Imágenes en Kind ===" -ForegroundColor Yellow
    if (Get-Command kind -ErrorAction SilentlyContinue) {
        foreach ($service in $services) {
            Write-Host "Cargando $service..." -ForegroundColor Cyan
            kind load docker-image "$service`:latest" --name ecommerce-cluster 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ $service cargado" -ForegroundColor Green
            } else {
                Write-Host "  ⚠ Error cargando $service (puede que la imagen no exista)" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "⚠ Kind no está instalado. Saltando carga de imágenes." -ForegroundColor Yellow
    }
}

# Paso 4: Aplicar ConfigMap
Write-Host ""
Write-Host "=== Paso 4: Aplicando ConfigMap ===" -ForegroundColor Yellow
try {
    kubectl create namespace $Namespace 2>&1 | Out-Null
    Write-Host "✓ Namespace $Namespace creado/verificado" -ForegroundColor Green
} catch {
    Write-Host "⚠ Namespace $Namespace ya existe o error al crearlo" -ForegroundColor Yellow
}

if (Test-Path "k8s\base\configmap.yaml") {
    kubectl apply -f k8s\base\configmap.yaml -n $Namespace 2>&1 | Out-Null
    Write-Host "✓ ConfigMap aplicado" -ForegroundColor Green
} else {
    Write-Host "⚠ ConfigMap no encontrado en k8s\base\configmap.yaml" -ForegroundColor Yellow
}

# Paso 5: Desplegar con Helm
if (-not $SkipDeploy) {
    Write-Host ""
    Write-Host "=== Paso 5: Desplegando con Helm ===" -ForegroundColor Yellow
    
    $chartPath = ".\helm\ecommerce-microservices"
    $valuesFile = ".\helm\ecommerce-microservices\values-$Environment.yaml"
    
    if (-not (Test-Path $valuesFile)) {
        Write-Host "⚠ Archivo de valores no encontrado: $valuesFile" -ForegroundColor Yellow
        $valuesFile = ".\helm\ecommerce-microservices\values.yaml"
    }
    
    # Verificar si el release ya existe
    $releaseExists = helm list --namespace $Namespace -q | Select-String $ReleaseName
    $helmCommand = if ($releaseExists) { "upgrade" } else { "install" }
    
    Write-Host "$helmCommand release '$ReleaseName'..." -ForegroundColor Cyan
    
    $helmArgs = @(
        $helmCommand,
        $ReleaseName,
        $chartPath,
        "--namespace", $Namespace,
        "-f", $valuesFile
    )
    
    # Para desarrollo local con Kind, usar imágenes locales
    if ($Environment -eq "dev" -and $LoadToKind) {
        $helmArgs += "--set", "global.registry="
        $helmArgs += "--set", "global.imagePullPolicy=Never"
    }
    
    helm @helmArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "✓ Despliegue completado exitosamente!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Comandos útiles:" -ForegroundColor Cyan
        Write-Host "  Ver pods:        kubectl get pods --namespace $Namespace" -ForegroundColor White
        Write-Host "  Ver servicios:   kubectl get services --namespace $Namespace" -ForegroundColor White
        Write-Host "  Ver logs:        kubectl logs -l app=<service-name> --namespace $Namespace" -ForegroundColor White
        Write-Host "  Estado Helm:     helm status $ReleaseName --namespace $Namespace" -ForegroundColor White
    } else {
        Write-Host ""
        Write-Host "✗ Error durante el despliegue" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Despliegue finalizado!" -ForegroundColor Green

