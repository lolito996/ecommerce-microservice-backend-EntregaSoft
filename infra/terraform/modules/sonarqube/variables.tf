variable "release_name" {
  description = "Nombre del release de Helm para SonarQube"
  type        = string
  default     = "sonarqube"
}

variable "chart_version" {
  description = "Versión del chart de SonarQube"
  type        = string
  default     = "10.6.0+3033"
}

variable "namespace" {
  description = "Namespace de Kubernetes donde desplegar SonarQube"
  type        = string
  default     = "sonarqube"
}

variable "create_namespace" {
  description = "Crear el namespace si no existe"
  type        = bool
  default     = true
}

variable "values_file" {
  description = "Ruta al archivo values.yaml personalizado"
  type        = string
  default     = ""
}

variable "set_values" {
  description = "Mapa de valores a establecer en el chart"
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Tiempo de espera en segundos para la instalación"
  type        = number
  default     = 600
}

variable "wait" {
  description = "Esperar a que todos los recursos estén listos"
  type        = bool
  default     = true
}

variable "depends_on_resources" {
  description = "Lista de recursos de los que depende este módulo"
  type        = list(any)
  default     = []
}
