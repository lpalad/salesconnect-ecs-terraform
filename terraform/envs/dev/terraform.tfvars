# Development Environment Values
# These values are specific to the dev environment

aws_region   = "ap-southeast-2"
project_name = "salesconnect"
environment  = "dev"

# Domain configuration
domain_name = "salesconnect.com.au"
subdomain   = "terraform"

# Network configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# ECS configuration
container_port = 8000
task_cpu       = 256   # 0.25 vCPU
task_memory    = 512   # 512 MB
desired_count  = 1
