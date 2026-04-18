variable "hosted_zone_id" {
  type = string
}

variable "app_record_name" {
  type = string
}

variable "origin_record_name" {
  type = string
}

variable "origin_record_target" {
  type = string
}

variable "cloudfront_domain_name" {
  type = string
}

variable "cloudfront_hosted_zone_id" {
  type = string
}

resource "aws_route53_record" "origin" {
  zone_id = var.hosted_zone_id
  name    = var.origin_record_name
  type    = "CNAME"
  ttl     = 60
  records = [var.origin_record_target]
}

resource "aws_route53_record" "app_alias" {
  zone_id = var.hosted_zone_id
  name    = var.app_record_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

output "app_record_fqdn" {
  value = aws_route53_record.app_alias.fqdn
}

output "origin_record_fqdn" {
  value = aws_route53_record.origin.fqdn
}
