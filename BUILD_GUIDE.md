# Build Guide

Complete step-by-step instructions to deploy ECS infrastructure with Terraform.

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] AWS CLI installed and configured (`aws --version`)
- [ ] Terraform installed (`terraform --version`)
- [ ] Docker installed and running (`docker --version`)
- [ ] GitHub account with this repo cloned
- [ ] AWS account with admin access
- [ ] Domain name (we're using `salesconnect.com.au`)

Verify AWS connection:
```bash
aws sts get-caller-identity
# Should show account: 480126395708
```

---

## Phase 1: Bootstrap Terraform Backend

Terraform needs a place to store its state file. We use S3 + DynamoDB for this.

### Step 1.1: Create S3 Bucket for State

```bash
aws s3 mb s3://salesconnect-terraform-state-480126395708 --region ap-southeast-2
```

### Step 1.2: Enable Versioning (Recommended)

```bash
aws s3api put-bucket-versioning \
    --bucket salesconnect-terraform-state-480126395708 \
    --versioning-configuration Status=Enabled
```

### Step 1.3: Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
    --table-name salesconnect-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ap-southeast-2
```

### Step 1.4: Verify Backend Resources

```bash
aws s3 ls | grep salesconnect
aws dynamodb list-tables --region ap-southeast-2 | grep salesconnect
```

---

## Phase 2: Deploy Infrastructure with Terraform

### Step 2.1: Navigate to Dev Environment

```bash
cd terraform/envs/dev
```

### Step 2.2: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 2.3: Review the Plan

```bash
terraform plan
```

This shows what Terraform will create. Review it carefully.

Expected resources:
- 1 VPC
- 2 Public subnets
- 2 Private subnets
- 1 NAT Gateway
- 1 Internet Gateway
- Route tables
- 1 ECS Cluster
- 1 ECS Service
- 1 Task Definition
- 1 ALB
- 1 Target Group
- Security Groups
- IAM Roles
- ACM Certificate
- Route53 Records

### Step 2.4: Apply Infrastructure

```bash
terraform apply
```

Type `yes` when prompted.

**This takes 3-5 minutes.** The longest part is ACM certificate validation.

### Step 2.5: Note the Outputs

After apply completes, note these values:
```
alb_dns_name = "salesconnect-alb-xxxxx.ap-southeast-2.elb.amazonaws.com"
ecr_repository_url = "480126395708.dkr.ecr.ap-southeast-2.amazonaws.com/salesconnect-api"
app_url = "https://terraform.salesconnect.com.au"
```

---

## Phase 3: Build and Deploy Application

### Step 3.1: Navigate to App Directory

```bash
cd ../../../app
```

### Step 3.2: Authenticate Docker to ECR

```bash
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 480126395708.dkr.ecr.ap-southeast-2.amazonaws.com
```

Expected output:
```
Login Succeeded
```

### Step 3.3: Build Docker Image

```bash
docker build -t salesconnect-api .
```

### Step 3.4: Tag Image for ECR

```bash
docker tag salesconnect-api:latest 480126395708.dkr.ecr.ap-southeast-2.amazonaws.com/salesconnect-api:latest
```

### Step 3.5: Push Image to ECR

```bash
docker push 480126395708.dkr.ecr.ap-southeast-2.amazonaws.com/salesconnect-api:latest
```

### Step 3.6: Force ECS Service Update

ECS needs to pull the new image:

```bash
aws ecs update-service \
    --cluster salesconnect-dev-cluster \
    --service salesconnect-dev-service \
    --force-new-deployment \
    --region ap-southeast-2
```

---

## Phase 4: Verify Deployment

### Step 4.1: Check ECS Service Status

```bash
aws ecs describe-services \
    --cluster salesconnect-dev-cluster \
    --services salesconnect-dev-service \
    --region ap-southeast-2 \
    --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'
```

Expected:
```json
{
    "Status": "ACTIVE",
    "Running": 1,
    "Desired": 1
}
```

### Step 4.2: Test the Application

```bash
# Test via ALB DNS
curl -s https://terraform.salesconnect.com.au/health | jq

# Expected response:
{
    "status": "healthy",
    "service": "salesconnect-api",
    "version": "1.0.0"
}
```

### Step 4.3: Test API Endpoint

```bash
curl -s https://terraform.salesconnect.com.au/ | jq
```

---

## Phase 5: Set Up GitHub Actions (CI/CD)

### Step 5.1: Add AWS Credentials to GitHub Secrets

Go to your repo: Settings → Secrets and variables → Actions → New repository secret

Add these secrets:
| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your terraform-admin access key |
| `AWS_SECRET_ACCESS_KEY` | Your terraform-admin secret key |
| `AWS_REGION` | `ap-southeast-2` |

### Step 5.2: Test the Pipeline

1. Create a new branch: `git checkout -b test-ci`
2. Make a small change to any file
3. Push: `git push origin test-ci`
4. Create a Pull Request
5. Watch the `terraform-plan` workflow run
6. Merge the PR
7. Watch the `terraform-apply` workflow run

---

## Troubleshooting

### Error: "No valid credential sources"
```bash
aws configure
# Re-enter your access key and secret key
```

### Error: "Certificate validation timed out"
ACM certificates require DNS validation. Check Route53 for the validation CNAME record.

### Error: "Service unable to place task"
Usually means the container is failing health checks. Check CloudWatch Logs:
```bash
aws logs tail /ecs/salesconnect-dev --follow --region ap-southeast-2
```

### Error: "AccessDenied" on ECR push
```bash
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 480126395708.dkr.ecr.ap-southeast-2.amazonaws.com
```

### ECS Task keeps restarting
Check the task stopped reason:
```bash
aws ecs describe-tasks \
    --cluster salesconnect-dev-cluster \
    --tasks $(aws ecs list-tasks --cluster salesconnect-dev-cluster --query 'taskArns[0]' --output text --region ap-southeast-2) \
    --region ap-southeast-2
```

---

## What You've Built

After completing this guide, you have:

1. **VPC** with public and private subnets across 2 AZs
2. **NAT Gateway** for private subnet internet access
3. **Application Load Balancer** with HTTPS listener
4. **ACM Certificate** for SSL/TLS
5. **Route53 DNS** pointing to your ALB
6. **ECS Fargate Cluster** running your containerized app
7. **ECR Repository** storing your Docker images
8. **IAM Roles** with least-privilege permissions
9. **GitHub Actions** CI/CD pipeline

This is a production-grade setup used by real companies.

---

## Next Steps

1. Review [TEARDOWN.md](TEARDOWN.md) to understand how to destroy resources
2. Try modifying the Flask app and pushing a new version
3. Explore the AWS Console to see what Terraform created
4. Tear down and rebuild to solidify your understanding
