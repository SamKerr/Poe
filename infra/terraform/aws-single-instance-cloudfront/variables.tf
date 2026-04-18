variable "aws_region" {
  description = "AWS region for EC2 and regional resources."
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name used in resource tags and names."
  type        = string
  default     = "poe"
}

variable "environment" {
  description = "Environment label used in naming/tagging."
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Root DNS zone name (for example: example.com)."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for domain_name."
  type        = string
}

variable "app_subdomain" {
  description = "Subdomain used for the CloudFront public endpoint."
  type        = string
  default     = "poe"
}

variable "origin_subdomain" {
  description = "Subdomain used as the CloudFront origin DNS name pointed at EC2."
  type        = string
  default     = "poe-origin"
}

variable "instance_type" {
  description = "EC2 instance type for the single app server."
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "Optional AMI ID override for EC2. Empty means latest Amazon Linux 2023."
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Optional subnet ID override inside default VPC."
  type        = string
  default     = null
}

variable "ssh_key_name" {
  description = "Optional EC2 key pair name for SSH access."
  type        = string
  default     = null
}

variable "enable_ssh_ingress" {
  description = "Whether to allow SSH ingress to the instance."
  type        = bool
  default     = false
}

variable "ssh_ingress_cidrs" {
  description = "CIDR blocks allowed for SSH when enable_ssh_ingress is true."
  type        = list(string)
  default     = []
}

variable "additional_app_ingress_cidrs" {
  description = "Additional CIDR blocks that can reach app port directly (beyond CloudFront origin-facing ranges)."
  type        = list(string)
  default     = []
}

variable "app_port" {
  description = "Port exposed by the Poe app container on EC2."
  type        = number
  default     = 8080
}

variable "app_image" {
  description = "Container image used by the EC2 runtime."
  type        = string
  default     = "ghcr.io/sam/poe:latest"
}

variable "sqlite_ebs_size_gb" {
  description = "Size of the EBS volume used for SQLite data."
  type        = number
  default     = 20
}

variable "sqlite_ebs_type" {
  description = "EBS volume type used for SQLite data."
  type        = string
  default     = "gp3"
}

variable "sqlite_device_name" {
  description = "Device name used for EBS attachment."
  type        = string
  default     = "/dev/sdf"
}

variable "viewer_min_tls_version" {
  description = "Minimum TLS version for CloudFront viewers."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "static_cache_path_patterns" {
  description = "Static asset path patterns that should be cached at CloudFront."
  type        = list(string)
  default = [
    "/css/*",
    "/js/*",
    "/images/*",
    "/webjars/*",
    "/swagger-ui/*",
    "/favicon.ico"
  ]
}

variable "tags" {
  description = "Additional tags applied to created resources."
  type        = map(string)
  default     = {}
}
