# AWS Single-Instance + CloudFront Terraform

This stack provisions a simple production-style deployment for Poe:

- CloudFront as HTTPS public edge
- Single EC2 instance as origin runtime
- Dedicated EBS volume mounted for SQLite persistence
- Route53 records for public app and CloudFront origin DNS
- ACM certificate in `us-east-1` for CloudFront

Use `terraform.tfvars.example` as your starting point.
