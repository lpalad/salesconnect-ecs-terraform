# Teardown Guide

Instructions to completely destroy all AWS resources and stop incurring costs.

## Cost Warning

If you leave resources running:

| Duration | Estimated Cost |
|----------|----------------|
| 1 day | ~$2.50 AUD |
| 3 days | ~$7.50 AUD |
| 1 week | ~$17.50 AUD |
| 1 month | ~$75 AUD |

**The NAT Gateway alone costs ~$1.10/day** even with zero traffic.

---

## Quick Teardown (Recommended)

### Step 1: Destroy Terraform Resources

```bash
cd terraform/envs/dev
terraform destroy
```

Type `yes` when prompted.

**This takes 3-5 minutes.** NAT Gateway deletion is the slowest.

### Step 2: Verify Destruction

```bash
terraform show
```

Should output: `No state.` or show empty state.

---

## Manual Cleanup (If Terraform Destroy Fails)

Sometimes Terraform can't delete everything. Here's manual cleanup:

### Delete ECS Service First

```bash
# Scale service to 0
aws ecs update-service \
    --cluster salesconnect-dev-cluster \
    --service salesconnect-dev-service \
    --desired-count 0 \
    --region ap-southeast-2

# Wait 30 seconds, then delete service
aws ecs delete-service \
    --cluster salesconnect-dev-cluster \
    --service salesconnect-dev-service \
    --force \
    --region ap-southeast-2
```

### Delete ECS Cluster

```bash
aws ecs delete-cluster \
    --cluster salesconnect-dev-cluster \
    --region ap-southeast-2
```

### Delete ALB

```bash
# Get ALB ARN
ALB_ARN=$(aws elbv2 describe-load-balancers \
    --names salesconnect-dev-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text \
    --region ap-southeast-2)

# Delete ALB
aws elbv2 delete-load-balancer \
    --load-balancer-arn $ALB_ARN \
    --region ap-southeast-2
```

### Delete NAT Gateway

```bash
# Get NAT Gateway ID
NAT_ID=$(aws ec2 describe-nat-gateways \
    --filter "Name=tag:Name,Values=*salesconnect*" \
    --query 'NatGateways[0].NatGatewayId' \
    --output text \
    --region ap-southeast-2)

# Delete NAT Gateway
aws ec2 delete-nat-gateway \
    --nat-gateway-id $NAT_ID \
    --region ap-southeast-2
```

### Delete VPC (Last)

```bash
# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=*salesconnect*" \
    --query 'Vpcs[0].VpcId' \
    --output text \
    --region ap-southeast-2)

# Delete VPC (this will fail if dependencies exist)
aws ec2 delete-vpc \
    --vpc-id $VPC_ID \
    --region ap-southeast-2
```

---

## Clean Up ECR Images (Optional)

ECR images cost ~$0.10/GB/month. Delete old images:

```bash
# Delete all images in repository
aws ecr batch-delete-image \
    --repository-name salesconnect-api \
    --image-ids "$(aws ecr list-images --repository-name salesconnect-api --query 'imageIds[*]' --output json --region ap-southeast-2)" \
    --region ap-southeast-2
```

---

## Keep Backend Resources (Recommended)

**DO NOT DELETE** the S3 bucket and DynamoDB table used for Terraform state:

- `s3://salesconnect-terraform-state-480126395708`
- `salesconnect-terraform-locks` (DynamoDB)

These cost almost nothing (<$0.01/month) and you need them to rebuild.

If you really want to delete them:

```bash
# Empty and delete S3 bucket
aws s3 rm s3://salesconnect-terraform-state-480126395708 --recursive
aws s3 rb s3://salesconnect-terraform-state-480126395708

# Delete DynamoDB table
aws dynamodb delete-table \
    --table-name salesconnect-terraform-locks \
    --region ap-southeast-2
```

---

## Verify Everything is Gone

### Check for Running Resources

```bash
# ECS Clusters
aws ecs list-clusters --region ap-southeast-2

# Load Balancers
aws elbv2 describe-load-balancers --region ap-southeast-2

# NAT Gateways
aws ec2 describe-nat-gateways \
    --filter "Name=state,Values=available" \
    --region ap-southeast-2

# VPCs (excluding default)
aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=false" \
    --region ap-southeast-2
```

### Check AWS Cost Explorer

Wait 24 hours, then check:
1. Go to AWS Console → Billing → Cost Explorer
2. Filter by service
3. Should show $0 for ECS, NAT Gateway, ALB

---

## Rebuild Instructions

To rebuild after teardown:

```bash
cd terraform/envs/dev
terraform init
terraform plan
terraform apply
```

Then rebuild and push Docker image:

```bash
cd ../../../app
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 480126395708.dkr.ecr.ap-southeast-2.amazonaws.com
docker build -t salesconnect-api .
docker tag salesconnect-api:latest 480126395708.dkr.ecr.ap-southeast-2.amazonaws.com/salesconnect-api:latest
docker push 480126395708.dkr.ecr.ap-southeast-2.amazonaws.com/salesconnect-api:latest
```

---

## Iteration Tracking

Use this to track your build/teardown cycles:

| Iteration | Date Built | Date Torn Down | Notes |
|-----------|------------|----------------|-------|
| 1 | | | First build, following guide |
| 2 | | | From memory, minimal guide reference |
| 3 | | | No guide, just commands |
| 4 | | | Added custom modifications |
| 5 | | | Could teach someone else |

**Goal:** By iteration 5, you should be able to build this from memory.
