variable "name_prefix" {
  type = string
}

variable "aliases" {
  type = list(string)
}

variable "origin_domain_name" {
  type = string
}

variable "origin_id" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "viewer_min_tls_version" {
  type = string
}

variable "static_cache_path_patterns" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  managed_cache_policy_caching_optimized = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  managed_cache_policy_caching_disabled  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  managed_origin_request_all_viewer_no_host = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.name_prefix} distribution"
  aliases         = var.aliases

  origin {
    domain_name = var.origin_domain_name
    origin_id   = var.origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id           = var.origin_id
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    compress                   = true
    cache_policy_id            = local.managed_cache_policy_caching_disabled
    origin_request_policy_id   = local.managed_origin_request_all_viewer_no_host
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.static_cache_path_patterns

    content {
      path_pattern               = ordered_cache_behavior.value
      target_origin_id           = var.origin_id
      viewer_protocol_policy     = "redirect-to-https"
      allowed_methods            = ["GET", "HEAD", "OPTIONS"]
      cached_methods             = ["GET", "HEAD", "OPTIONS"]
      compress                   = true
      cache_policy_id            = local.managed_cache_policy_caching_optimized
      origin_request_policy_id   = local.managed_origin_request_all_viewer_no_host
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.viewer_min_tls_version
  }

  tags = var.tags
}

output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  value = aws_cloudfront_distribution.this.hosted_zone_id
}
