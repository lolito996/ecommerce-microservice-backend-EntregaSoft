variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  type    = map(string)
  default = { Project = "ecommerce", Environment = "production" }
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes para EKS"
  type        = string
  default     = "1.28"
}

variable "desired_node_count" {
  description = "Número deseado de nodos en el cluster EKS"
  type        = number
  default     = 3
}

variable "min_node_count" {
  description = "Número mínimo de nodos"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Número máximo de nodos"
  type        = number
  default     = 6
}

variable "instance_type" {
  description = "Tipo de instancia EC2 para los nodos"
  type        = string
  default     = "t3.large"
}

variable "sonarqube_chart_version" {
  description = "Versión del chart de SonarQube"
  type        = string
  default     = "10.6.0+3033"
}

variable "helm_chart_repository" {
  description = "Repositorio Helm para microservicios"
  type        = string
  default     = ""
}

variable "helm_chart_name" {
  description = "Nombre del chart de microservicios"
  type        = string
  default     = "ecommerce"
}

variable "helm_chart_version" {
  description = "Versión del chart de microservicios"
  type        = string
  default     = "1.0.0"
}
