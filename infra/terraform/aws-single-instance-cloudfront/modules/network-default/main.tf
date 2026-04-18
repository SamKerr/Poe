data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

output "default_vpc_id" {
  description = "Default VPC ID."
  value       = data.aws_vpc.default.id
}

output "default_subnet_ids" {
  description = "Subnet IDs from the default VPC."
  value       = data.aws_subnets.default_vpc_subnets.ids
}
