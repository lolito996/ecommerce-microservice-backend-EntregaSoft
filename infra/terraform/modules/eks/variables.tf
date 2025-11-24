variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs de las subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las subnets privadas"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "instance_type" {
  description = "Tipo de instancia para los nodos"
  type        = string
  default     = "t3.medium"
}

variable "desired_size" {
  description = "Número deseado de nodos"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Número mínimo de nodos"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Número máximo de nodos"
  type        = number
  default     = 4
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
}
