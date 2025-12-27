# Terraform Backend Configuration
# Stores state in S3 with DynamoDB locking

terraform {
  backend "s3" {
    bucket         = "salesconnect-terraform-state-<YOUR-ACCOUNT-ID>"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "salesconnect-terraform-locks"
    encrypt        = true
  }
}
