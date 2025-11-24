variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3 para el estado de Terraform (debe ser único globalmente)"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para lock del estado"
  type        = string
  default     = "ecom-terraform-locks"
}

variable "tags" {
  description = "Tags comunes"
  type        = map(string)
  default = {
    Project     = "ecommerce"
    Environment = "shared"
    Purpose     = "terraform-backend"
  }
}
