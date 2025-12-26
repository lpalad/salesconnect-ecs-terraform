# Development Environment Outputs
# These values are displayed after terraform apply

# Application URL
output "app_url" {
  description = "URL to access the application"
  value       = module.acm_route53.app_url
}

# ALB Information
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

# ECR Repository
output "ecr_repository_url" {
  description = "URL of the ECR repository for Docker images"
  value       = module.ecs.ecr_repository_url
}

# ECS Cluster
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

# Network Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.network.private_subnet_ids
}

# Useful Commands
output "docker_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.ecs.ecr_repository_url}"
}

output "docker_push_commands" {
  description = "Commands to build and push Docker image"
  value = <<-EOT
    cd app
    docker build -t salesconnect-api .
    docker tag salesconnect-api:latest ${module.ecs.ecr_repository_url}:latest
    docker push ${module.ecs.ecr_repository_url}:latest
  EOT
}

output "ecs_update_command" {
  description = "Command to force ECS service update"
  value       = "aws ecs update-service --cluster ${module.ecs.cluster_name} --service ${module.ecs.service_name} --force-new-deployment --region ${var.aws_region}"
}

output "logs_command" {
  description = "Command to tail ECS logs"
  value       = "aws logs tail ${module.iam.cloudwatch_log_group_name} --follow --region ${var.aws_region}"
}
