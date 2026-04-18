variable "name" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "size_gb" {
  type = number
}

variable "volume_type" {
  type = string
}

variable "device_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_ebs_volume" "sqlite" {
  availability_zone = var.availability_zone
  size              = var.size_gb
  type              = var.volume_type
  encrypted         = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_volume_attachment" "sqlite" {
  device_name = var.device_name
  volume_id   = aws_ebs_volume.sqlite.id
  instance_id = var.instance_id
}

output "volume_id" {
  value = aws_ebs_volume.sqlite.id
}
