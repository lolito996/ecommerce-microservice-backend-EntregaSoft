output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.terraform_backend.s3_bucket_id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = module.terraform_backend.dynamodb_table_id
}

output "backend_config_file" {
  description = "Path to the backend configuration file"
  value       = local_file.backend_config.filename
}

output "instructions" {
  description = "Next steps instructions"
  value       = <<-EOT
    
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                    Backend Created Successfully!                         ║
    ╚══════════════════════════════════════════════════════════════════════════╝
    
    Next Steps:
    
    1. Review the backend configuration in: ${local_file.backend_config.filename}
    
    2. Update backend.tf in each environment (dev, stage, prod) with:
       - bucket: ${module.terraform_backend.s3_bucket_id}
       - dynamodb_table: ${module.terraform_backend.dynamodb_table_id}
       - region: ${var.aws_region}
    
    3. Initialize each environment:
       cd infra/aws-environments/dev && terraform init
       cd infra/aws-environments/stage && terraform init
       cd infra/aws-environments/prod && terraform init
    
    4. Deploy your infrastructure!
    
  EOT
}
