#!/bin/bash

# Script to deploy Prometheus and Grafana to Kubernetes
# Usage: ./scripts/deploy-monitoring.sh <namespace> <prometheus-nodeport> <grafana-nodeport>

set -e

NAMESPACE=${1:-microservices-staging}
PROMETHEUS_NODEPORT=${2:-30090}
GRAFANA_NODEPORT=${3:-30091}

echo "Deploying Prometheus and Grafana to namespace: ${NAMESPACE}"
echo "Prometheus NodePort: ${PROMETHEUS_NODEPORT}"
echo "Grafana NodePort: ${GRAFANA_NODEPORT}"

# Apply Prometheus
sed -e "s|\${NAMESPACE}|${NAMESPACE}|g" \
    -e "s|\${NODE_PORT}|${PROMETHEUS_NODEPORT}|g" \
    k8s/base/prometheus.yaml | kubectl apply -f -

# Apply Grafana
sed -e "s|\${NAMESPACE}|${NAMESPACE}|g" \
    -e "s|\${NODE_PORT}|${GRAFANA_NODEPORT}|g" \
    k8s/base/grafana.yaml | kubectl apply -f -

echo "Waiting for Prometheus and Grafana to be ready..."
kubectl wait --for=condition=ready pod -l app=prometheus -n ${NAMESPACE} --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=grafana -n ${NAMESPACE} --timeout=300s || true

echo "Prometheus and Grafana deployed successfully!"
echo "Prometheus: http://localhost:${PROMETHEUS_NODEPORT}"
echo "Grafana: http://localhost:${GRAFANA_NODEPORT} (admin/admin)"

