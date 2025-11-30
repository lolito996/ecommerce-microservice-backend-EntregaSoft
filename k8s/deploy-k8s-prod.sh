#!/bin/bash

# Script para desplegar todos los servicios a Kubernetes (producción)
# Uso: ./deploy-k8s-prod.sh [image_tag]

set -e

# Configuración
NAMESPACE="microservices-prod"
REGISTRY="ghcr.io/lolito996"
IMAGE_TAG="${1:-latest}"

echo "🚀 Desplegando a Kubernetes - Producción"
echo "📦 Registry: $REGISTRY"
echo "🏷️  Image Tag: $IMAGE_TAG"
echo "📍 Namespace: $NAMESPACE"
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para procesar y aplicar manifiestos
apply_manifest() {
    local file=$1
    local service_name=$(basename "$file" .yaml)
    
    echo -e "${YELLOW}📦 Aplicando: $service_name${NC}"
    
    # Reemplazar variables y aplicar
    cat "$file" | \
        sed "s|\${NAMESPACE}|$NAMESPACE|g" | \
        sed "s|\${REGISTRY}|$REGISTRY|g" | \
        sed "s|\${IMAGE_TAG}|$IMAGE_TAG|g" | \
        sed "s|\${NODE_PORT}|30080|g" | \
        kubectl apply -f -
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $service_name aplicado${NC}"
    else
        echo -e "${RED}❌ Error aplicando $service_name${NC}"
        return 1
    fi
    echo ""
}

# Verificar conexión a cluster
echo "🔍 Verificando conexión al cluster..."
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ No se puede conectar al cluster de Kubernetes${NC}"
    echo "Ejecuta: aws eks update-kubeconfig --region us-east-1 --name prod-ecommerce-cluster"
    exit 1
fi
echo -e "${GREEN}✅ Conectado al cluster${NC}"
echo ""

# Crear namespace si no existe
echo "📁 Creando namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo ""

# Aplicar ConfigMap de producción
echo "⚙️  Aplicando ConfigMap..."
kubectl apply -f k8s/production/configmap.yaml
echo ""

# Aplicar servicios internos (cloud-config, zipkin)
echo "🔧 Aplicando servicios internos..."
kubectl apply -f k8s/production/internal-services.yaml
echo ""

# Desplegar servicios de infraestructura primero
echo "🏗️  Desplegando servicios de infraestructura..."
INFRA_SERVICES=(
    "k8s/base/service-discovery.yaml"
    "k8s/base/cloud-config.yaml"
    "k8s/base/zipkin.yaml"
)

for service in "${INFRA_SERVICES[@]}"; do
    if [ -f "$service" ]; then
        apply_manifest "$service"
    else
        echo -e "${YELLOW}⚠️  Archivo no encontrado: $service${NC}"
    fi
done

echo "⏳ Esperando 60 segundos para que los servicios de infraestructura estén listos..."
sleep 60

# Desplegar servicios de aplicación
echo "📦 Desplegando servicios de aplicación..."
APP_SERVICES=(
    "k8s/base/api-gateway.yaml"
    "k8s/base/user-service.yaml"
    "k8s/base/product-service.yaml"
    "k8s/base/order-service.yaml"
    "k8s/base/payment-service.yaml"
    "k8s/base/shipping-service.yaml"
    "k8s/base/favourite-service.yaml"
    "k8s/base/proxy-client.yaml"
)

for service in "${APP_SERVICES[@]}"; do
    if [ -f "$service" ]; then
        apply_manifest "$service"
    else
        echo -e "${YELLOW}⚠️  Archivo no encontrado: $service${NC}"
    fi
done

# Aplicar configuración de Prometheus (si existe)
if [ -f "k8s/production/prometheus-config.yaml" ]; then
    echo "📊 Aplicando configuración de Prometheus..."
    kubectl apply -f k8s/production/prometheus-config.yaml
fi

# Mostrar estado de deployments
echo ""
echo "📊 Estado de los deployments:"
kubectl get deployments -n $NAMESPACE -o wide

echo ""
echo "📋 Estado de los pods:"
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "🌐 Servicios expuestos:"
kubectl get svc -n $NAMESPACE -o wide

echo ""
echo -e "${GREEN}✅ Despliegue completado${NC}"
echo ""
echo "Para ver logs de un servicio:"
echo "  kubectl logs -f -l app=<service-name> -n $NAMESPACE"
echo ""
echo "Para verificar el estado:"
echo "  kubectl rollout status deployment/<service-name> -n $NAMESPACE"
