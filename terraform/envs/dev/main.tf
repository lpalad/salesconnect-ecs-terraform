# Main Terraform Configuration - Development Environment
# Orchestrates all modules to create the complete infrastructure

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# Network Module - VPC, Subnets, NAT Gateway
module "network" {
  source = "../../modules/network"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# IAM Module - ECS Roles and Policies
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

# ACM/Route53 Module - SSL Certificate and DNS
# Note: ALB must be created first to get DNS name
module "acm_route53" {
  source = "../../modules/acm_route53"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
  subdomain    = var.subdomain
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

# ALB Module - Application Load Balancer
module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  certificate_arn   = module.acm_route53.certificate_arn
  container_port    = var.container_port
  health_check_path = "/health"

  depends_on = [module.acm_route53]
}

# ECS Module - Cluster, Service, Task Definition
module "ecs" {
  source = "../../modules/ecs"

  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  vpc_id                    = module.network.vpc_id
  private_subnet_ids        = module.network.private_subnet_ids
  alb_security_group_id     = module.alb.alb_security_group_id
  target_group_arn          = module.alb.target_group_arn
  execution_role_arn        = module.iam.ecs_task_execution_role_arn
  task_role_arn             = module.iam.ecs_task_role_arn
  cloudwatch_log_group_name = module.iam.cloudwatch_log_group_name
  container_port            = var.container_port
  task_cpu                  = var.task_cpu
  task_memory               = var.task_memory
  desired_count             = var.desired_count

  depends_on = [module.alb, module.iam]
}
