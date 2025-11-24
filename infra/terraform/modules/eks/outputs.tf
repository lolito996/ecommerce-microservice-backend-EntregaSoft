output "cluster_id" {
  description = "ID del cluster EKS"
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster EKS"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificado CA del cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_arn" {
  description = "ARN del cluster EKS"
  value       = aws_eks_cluster.this.arn
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "node_group_id" {
  description = "ID del node group"
  value       = aws_eks_node_group.this.id
}

output "cluster_security_group_id" {
  description = "Security group del cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

