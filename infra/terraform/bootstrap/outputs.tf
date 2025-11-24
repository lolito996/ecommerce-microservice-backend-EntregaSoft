output "s3_bucket_name" {
  description = "Nombre del bucket S3 creado"
  value       = aws_s3_bucket.tfstate.id
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.tfstate.arn
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para locks"
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "region" {
  description = "Región de AWS"
  value       = var.region
}

output "backend_config_example" {
  description = "Ejemplo de configuración para backend"
  value = <<-EOT
    bucket         = "${aws_s3_bucket.tfstate.id}"
    key            = "staging/terraform.tfstate"  # Cambiar según ambiente (staging/prod)
    region         = "${var.region}"
    dynamodb_table = "${aws_dynamodb_table.tfstate_lock.name}"
    encrypt        = true
  EOT
}
