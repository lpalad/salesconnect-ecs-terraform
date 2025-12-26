# ACM/Route53 Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (e.g., salesconnect.com.au)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for the application (e.g., terraform)"
  type        = string
  default     = ""
}
