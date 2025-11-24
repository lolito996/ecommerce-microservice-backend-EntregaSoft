variable "release_name" {
  description = "Nombre del release de Helm"
  type        = string
}

variable "repository" {
  description = "URL del repositorio Helm"
  type        = string
}

variable "chart" {
  description = "Nombre del chart"
  type        = string
}

variable "chart_version" {
  description = "Versión del chart"
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Namespace de Kubernetes"
  type        = string
  default     = "default"
}

variable "create_namespace" {
  description = "Crear el namespace si no existe"
  type        = bool
  default     = false
}

variable "values_files" {
  description = "Lista de archivos values.yaml"
  type        = list(string)
  default     = []
}

variable "set_values" {
  description = "Mapa de valores para sobrescribir"
  type        = map(string)
  default     = {}
}

variable "set_sensitive_values" {
  description = "Mapa de valores sensibles para sobrescribir"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "timeout" {
  description = "Timeout en segundos"
  type        = number
  default     = 300
}

variable "wait" {
  description = "Esperar a que todos los recursos estén listos"
  type        = bool
  default     = true
}

variable "force_update" {
  description = "Forzar actualización"
  type        = bool
  default     = false
}

variable "recreate_pods" {
  description = "Recrear pods en actualización"
  type        = bool
  default     = false
}

variable "depends_on_resources" {
  description = "Lista de recursos de los que depende"
  type        = list(any)
  default     = []
}
