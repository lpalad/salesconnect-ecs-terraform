# SalesConnect ECS Terraform

Production-grade ECS Fargate deployment with Terraform Infrastructure as Code and GitHub Actions CI/CD.

## Architecture

```
                                    ┌─────────────────────────────────────────────────────────┐
                                    │                        AWS Cloud                         │
                                    │                                                          │
┌──────────┐    HTTPS              │  ┌─────────────┐      ┌─────────────────────────────┐   │
│  Users   │ ──────────────────────┼─►│    ALB      │─────►│      ECS Fargate            │   │
└──────────┘                       │  │  (Public)   │      │   ┌─────────────────────┐   │   │
                                    │  └─────────────┘      │   │   Flask API         │   │   │
                                    │        │              │   │   (Private Subnet)  │   │   │
                                    │        │              │   └─────────────────────┘   │   │
                                    │        ▼              └─────────────────────────────┘   │
                                    │  ┌─────────────┐                    │                   │
                                    │  │  Route 53   │                    │                   │
                                    │  │  (DNS)      │                    ▼                   │
                                    │  └─────────────┘      ┌─────────────────────────────┐   │
                                    │        │              │       NAT Gateway           │   │
                                    │        ▼              │    (Outbound Internet)      │   │
                                    │  ┌─────────────┐      └─────────────────────────────┘   │
                                    │  │    ACM      │                                        │
                                    │  │  (SSL/TLS)  │                                        │
                                    │  └─────────────┘                                        │
                                    │                                                          │
                                    └─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    CI/CD Pipeline                                            │
│                                                                                              │
│  ┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐               │
│  │  GitHub  │────►│  Terraform   │────►│    Build     │────►│   Deploy     │               │
│  │   Push   │     │  Plan/Apply  │     │ Docker Image │     │   to ECS     │               │
│  └──────────┘     └──────────────┘     └──────────────┘     └──────────────┘               │
│                                                                                              │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
salesconnect-ecs-terraform/
├── README.md                 # This file
├── BUILD_GUIDE.md            # Step-by-step build instructions
├── TEARDOWN.md               # Destroy instructions + cost warnings
├── terraform/
│   ├── envs/
│   │   └── dev/              # Development environment
│   │       ├── backend.tf    # S3 backend configuration
│   │       ├── main.tf       # Module orchestration
│   │       ├── variables.tf  # Input variables
│   │       ├── outputs.tf    # Output values
│   │       └── terraform.tfvars  # Variable values
│   └── modules/
│       ├── network/          # VPC, subnets, NAT, routes
│       ├── ecs/              # Cluster, service, task definitions
│       ├── alb/              # Load balancer, target groups
│       ├── acm_route53/      # SSL certificate + DNS
│       └── iam/              # Task execution roles, policies
├── app/
│   ├── Dockerfile            # Container build instructions
│   ├── requirements.txt      # Python dependencies
│   └── src/
│       └── main.py           # Flask API application
└── .github/
    └── workflows/
        ├── terraform-plan.yml    # PR: shows infrastructure changes
        ├── terraform-apply.yml   # Merge: applies infrastructure
        └── build-deploy.yml      # Builds and deploys container
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Infrastructure as Code | Terraform 1.14+ |
| Container Orchestration | AWS ECS Fargate |
| Load Balancer | AWS Application Load Balancer |
| SSL/TLS | AWS Certificate Manager |
| DNS | AWS Route 53 |
| Container Registry | AWS ECR |
| CI/CD | GitHub Actions |
| Application | Python Flask |

## Quick Start

See [BUILD_GUIDE.md](BUILD_GUIDE.md) for complete step-by-step instructions.

```bash
# 1. Bootstrap Terraform backend
cd terraform/envs/dev
aws s3 mb s3://salesconnect-terraform-state-480126395708 --region ap-southeast-2
aws dynamodb create-table \
    --table-name salesconnect-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ap-southeast-2

# 2. Initialize and apply
terraform init
terraform plan
terraform apply

# 3. Build and push Docker image
cd ../../../app
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-2.amazonaws.com
docker build -t salesconnect-api .
docker tag salesconnect-api:latest <account-id>.dkr.ecr.ap-southeast-2.amazonaws.com/salesconnect-api:latest
docker push <account-id>.dkr.ecr.ap-southeast-2.amazonaws.com/salesconnect-api:latest
```

## Estimated Costs (3 days)

| Resource | 3-Day Cost |
|----------|------------|
| NAT Gateway | ~$3.50 |
| ALB | ~$2.00 |
| ECS Fargate | ~$0.75 |
| Other (ECR, Route53, logs) | ~$0.25 |
| **Total** | **~$6.50 AUD** |

## Teardown

See [TEARDOWN.md](TEARDOWN.md) for complete destroy instructions.

```bash
cd terraform/envs/dev
terraform destroy
```

## Author

Leonard Palad - ML Platform Engineer | DevOps

## License

MIT
