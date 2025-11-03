# Script rápido para configurar Kubernetes y probar pipelines

Write-Host "1. Instalando Kind..." -ForegroundColor Cyan
if (!(Get-Command kind -ErrorAction SilentlyContinue)) {
    Write-Host "Kind no encontrado. Instalando..." -ForegroundColor Yellow
    choco install kind -y
    # O manualmente: https://kind.sigs.k8s.io/docs/user/quick-start/#installation
}

Write-Host "2. Creando cluster Kind..." -ForegroundColor Cyan
kind create cluster --config kind.yml --name ecommerce-cluster

Write-Host "3. Aplicando namespaces..." -ForegroundColor Cyan
kubectl apply -f k8s/base/namespaces.yaml

Write-Host "4. Configurando kubeconfig..." -ForegroundColor Cyan
$KUBECONFIG_PATH = "$env:USERPROFILE\.kube\kind-ecommerce-cluster-config"
kind get kubeconfig --name ecommerce-cluster > $KUBECONFIG_PATH
$env:KUBECONFIG = $KUBECONFIG_PATH

Write-Host "✓ Kubernetes configurado!" -ForegroundColor Green
Write-Host "Para usar este kubeconfig en Jenkins, cópialo a: $KUBECONFIG_PATH" -ForegroundColor Yellow




