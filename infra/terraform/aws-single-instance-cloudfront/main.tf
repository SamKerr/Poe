locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  app_fqdn           = "${var.app_subdomain}.${var.domain_name}"
  origin_fqdn        = "${var.origin_subdomain}.${var.domain_name}"
  selected_subnet_id = var.subnet_id != null ? var.subnet_id : module.network_default.default_subnet_ids[0]
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Sprint      = "3"
    },
    var.tags
  )
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

module "network_default" {
  source = "./modules/network-default"
}

module "security_group" {
  source = "./modules/security-group"

  name                          = "${local.name_prefix}-app-sg"
  vpc_id                        = module.network_default.default_vpc_id
  app_port                      = var.app_port
  cloudfront_prefix_list_id     = data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id
  additional_app_ingress_cidrs  = var.additional_app_ingress_cidrs
  enable_ssh_ingress            = var.enable_ssh_ingress
  ssh_ingress_cidrs             = var.ssh_ingress_cidrs
  tags                          = local.common_tags
}

module "instance_profile" {
  source = "./modules/instance-profile"

  name = "${local.name_prefix}-ec2"
  tags = local.common_tags
}

module "ec2" {
  source = "./modules/ec2"

  name                    = "${local.name_prefix}-app"
  ami_id                  = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type           = var.instance_type
  subnet_id               = local.selected_subnet_id
  security_group_ids      = [module.security_group.security_group_id]
  iam_instance_profile    = module.instance_profile.instance_profile_name
  key_name                = var.ssh_key_name
  user_data               = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    app_port              = var.app_port
    app_image             = var.app_image
    sqlite_device_name    = var.sqlite_device_name
    sqlite_mount_path     = "/data/poe"
  })
  tags                    = local.common_tags
}

module "ebs" {
  source = "./modules/ebs"

  name           = "${local.name_prefix}-sqlite"
  availability_zone = module.ec2.availability_zone
  instance_id    = module.ec2.instance_id
  size_gb        = var.sqlite_ebs_size_gb
  volume_type    = var.sqlite_ebs_type
  device_name    = var.sqlite_device_name
  tags           = local.common_tags
}

module "route53" {
  source = "./modules/route53"

  hosted_zone_id                = var.hosted_zone_id
  app_record_name               = local.app_fqdn
  origin_record_name            = local.origin_fqdn
  origin_record_target          = module.ec2.public_dns
  cloudfront_domain_name        = module.cloudfront.domain_name
  cloudfront_hosted_zone_id     = module.cloudfront.hosted_zone_id
}

module "acm_cloudfront" {
  source = "./modules/acm-cloudfront"

  providers = {
    aws = aws.us_east_1
  }

  domain_name    = local.app_fqdn
  hosted_zone_id = var.hosted_zone_id
  tags           = local.common_tags
}

module "cloudfront" {
  source = "./modules/cloudfront"

  name_prefix                   = local.name_prefix
  aliases                       = [local.app_fqdn]
  origin_domain_name            = local.origin_fqdn
  origin_id                     = "${local.name_prefix}-origin"
  acm_certificate_arn           = module.acm_cloudfront.certificate_arn
  viewer_min_tls_version        = var.viewer_min_tls_version
  static_cache_path_patterns    = var.static_cache_path_patterns
  tags                          = local.common_tags
}
