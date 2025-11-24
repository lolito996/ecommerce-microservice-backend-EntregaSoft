resource "helm_release" "sonarqube" {
  name       = var.release_name
  repository = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart      = "sonarqube"
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = var.create_namespace
  timeout          = var.timeout
  wait             = var.wait

  values = var.values_file != "" ? [file(var.values_file)] : []

  dynamic "set" {
    for_each = var.set_values
    content {
      name  = set.key
      value = set.value
    }
  }
}
