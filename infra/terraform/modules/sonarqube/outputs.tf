output "release_name" {
  description = "Nombre del release de Helm"
  value       = helm_release.sonarqube.name
}

output "namespace" {
  description = "Namespace donde está desplegado SonarQube"
  value       = helm_release.sonarqube.namespace
}

output "status" {
  description = "Estado del release"
  value       = helm_release.sonarqube.status
}
