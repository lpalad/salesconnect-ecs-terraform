# ACM/Route53 Module Outputs

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "certificate_domain" {
  description = "Domain name of the certificate"
  value       = aws_acm_certificate.main.domain_name
}

output "hosted_zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = data.aws_route53_zone.main.zone_id
}
