# Terraform Backend Configuration
# Stores state in S3 with DynamoDB locking

terraform {
  backend "s3" {
    bucket         = "salesconnect-terraform-state-480126395708"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "salesconnect-terraform-locks"
    encrypt        = true
  }
}
