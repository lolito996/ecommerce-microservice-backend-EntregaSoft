locals {
  cluster_name = "ecom-prod-eks"
}

# EKS Cluster con VPC
module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version
  desired_size       = var.desired_node_count
  min_size           = var.min_node_count
  max_size           = var.max_node_count
  instance_type      = var.instance_type

  tags = merge(
    var.tags,
    {
      Environment = "production"
    }
  )
}

# SonarQube via Helm
module "sonarqube" {
  source = "../../modules/sonarqube"

  release_name     = "sonarqube"
  chart_version    = var.sonarqube_chart_version
  namespace        = "sonarqube"
  create_namespace = true
  timeout          = 900  # 15 minutos para instalación

  set_values = {
    "service.type"                    = "LoadBalancer"
    "persistence.enabled"             = "true"
    "persistence.size"                = "20Gi"
    "postgresql.persistence.enabled"  = "true"
    "postgresql.persistence.size"     = "20Gi"
    "resources.requests.cpu"          = "500m"
    "resources.requests.memory"       = "2Gi"
  }
}

# NOTA: Los microservicios se despliegan con kubectl después
# usando los manifiestos en k8s/base/
# Ejecutar: kubectl apply -f k8s/base/ -n ecommerce
