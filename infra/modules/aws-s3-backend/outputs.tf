output "s3_bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_id" {
  description = "DynamoDB table ID"
  value       = aws_dynamodb_table.terraform_locks.id
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "backend_policy_arn" {
  description = "IAM policy ARN for backend access"
  value       = var.create_backend_policy ? aws_iam_policy.terraform_backend[0].arn : null
}
