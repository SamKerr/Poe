output "app_url" {
  description = "Public app URL served by CloudFront."
  value       = "https://${local.app_fqdn}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name."
  value       = module.cloudfront.domain_name
}

output "ec2_instance_id" {
  description = "EC2 instance ID running the app."
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "EC2 public IP."
  value       = module.ec2.public_ip
}

output "origin_domain_name" {
  description = "DNS name used by CloudFront origin."
  value       = local.origin_fqdn
}

output "route53_app_record_fqdn" {
  description = "Route53 FQDN for the public app record."
  value       = module.route53.app_record_fqdn
}

output "route53_origin_record_fqdn" {
  description = "Route53 FQDN for the CloudFront origin record."
  value       = module.route53.origin_record_fqdn
}

output "sqlite_ebs_volume_id" {
  description = "EBS volume ID used for SQLite persistence."
  value       = module.ebs.volume_id
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN provisioned in us-east-1 for CloudFront."
  value       = module.acm_cloudfront.certificate_arn
}
