output "release_name" {
  description = "Nombre del release"
  value       = helm_release.this.name
}

output "namespace" {
  description = "Namespace del release"
  value       = helm_release.this.namespace
}

output "status" {
  description = "Estado del release"
  value       = helm_release.this.status
}

output "version" {
  description = "Versión del chart desplegado"
  value       = helm_release.this.version
}
