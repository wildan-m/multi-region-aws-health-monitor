output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.compute.load_balancer_dns_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_instance_endpoint
  sensitive   = true
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}