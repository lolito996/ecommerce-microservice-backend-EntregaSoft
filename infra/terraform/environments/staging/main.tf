locals {
  cluster_name = "ecom-staging-eks"
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
      Environment = "staging"
    }
  )
}

# SonarQube via Helm (Comentado temporalmente - problemas con PostgreSQL)
# Puedes instalarlo manualmente después con kubectl
# module "sonarqube" {
#   source = "../../modules/sonarqube"
#
#   release_name     = "sonarqube"
#   chart_version    = var.sonarqube_chart_version
#   namespace        = "sonarqube"
#   create_namespace = true
#   timeout          = 900  
#
#   set_values = {
#     "service.type"                    = "LoadBalancer"
#     "persistence.enabled"             = "false"  
#     "postgresql.persistence.enabled"  = "false"
#     "postgresql.image.tag"            = "15.3.0"
#   }
# }
