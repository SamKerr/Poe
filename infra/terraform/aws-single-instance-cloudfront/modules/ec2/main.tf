variable "name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "iam_instance_profile" {
  type = string
}

variable "key_name" {
  type    = string
  default = null
}

variable "user_data" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.iam_instance_profile
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = var.user_data
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

output "instance_id" {
  value = aws_instance.app.id
}

output "availability_zone" {
  value = aws_instance.app.availability_zone
}

output "public_ip" {
  value = aws_instance.app.public_ip
}

output "public_dns" {
  value = aws_instance.app.public_dns
}
