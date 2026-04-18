variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_port" {
  type = number
}

variable "cloudfront_prefix_list_id" {
  type = string
}

variable "additional_app_ingress_cidrs" {
  type    = list(string)
  default = []
}

variable "enable_ssh_ingress" {
  type    = bool
  default = false
}

variable "ssh_ingress_cidrs" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_security_group" "app" {
  name        = var.name
  description = "Security group for single-instance Poe app"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "app_from_cloudfront" {
  security_group_id = aws_security_group.app.id
  from_port         = var.app_port
  to_port           = var.app_port
  ip_protocol       = "tcp"
  prefix_list_id    = var.cloudfront_prefix_list_id
  description       = "App ingress from CloudFront origin-facing ranges"
}

resource "aws_vpc_security_group_ingress_rule" "app_from_extra_cidrs" {
  for_each = toset(var.additional_app_ingress_cidrs)

  security_group_id = aws_security_group.app.id
  from_port         = var.app_port
  to_port           = var.app_port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  description       = "Additional app ingress CIDR"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = var.enable_ssh_ingress ? toset(var.ssh_ingress_cidrs) : toset([])

  security_group_id = aws_security_group.app.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  description       = "Optional SSH ingress"
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}

output "security_group_id" {
  value = aws_security_group.app.id
}
