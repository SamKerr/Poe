# Cloud Deployment (Sprint 3: T17, T18, T20)

This guide deploys Poe using a single EC2 instance behind CloudFront, with SQLite data persisted on EBS.

## Architecture

Single-instance architecture for this sprint:

```text
Users
  |
  v
Route53 A/ALIAS (poe.example.com)
  |
  v
CloudFront Distribution (HTTPS, ACM in us-east-1)
  |
  v
Route53 CNAME (poe-origin.example.com)
  |
  v
EC2 (Amazon Linux 2023, Docker runtime)
  |
  v
Container: ghcr.io/sam/poe:latest (port 8080)
  |
  v
EBS volume mounted at /data/poe -> /app/data in container (SQLite)
```

## What Terraform provisions

Under `infra/terraform/aws-single-instance-cloudfront`:

- Default VPC and default subnet discovery
- Security group:
  - app port ingress from CloudFront origin-facing AWS managed prefix list
  - optional SSH ingress from operator-provided CIDRs
  - all outbound egress
- EC2 IAM role + instance profile (SSM managed instance policy attached)
- Single EC2 instance running user-data bootstrap
- Encrypted EBS volume + attachment for SQLite persistence
- ACM certificate in `us-east-1` with DNS validation
- CloudFront distribution:
  - default behavior uses disabled caching for dynamic routes
  - ordered behaviors cache static paths (`/css/*`, `/js/*`, `/images/*`, `/webjars/*`, `/swagger-ui/*`, `/favicon.ico`)
- Route53 records:
  - public app alias record -> CloudFront
  - origin CNAME record -> EC2 public DNS

## Prerequisites

- AWS credentials configured locally (`aws configure` or environment variables)
- Existing Route53 hosted zone for your domain
- Terraform `>= 1.6`
- A container image accessible from EC2 (`app_image` variable)

## Configure variables

```bash
cd infra/terraform/aws-single-instance-cloudfront
cp terraform.tfvars.example terraform.tfvars
```

Set at least:

- `domain_name`
- `hosted_zone_id`
- `app_image`

Optional but commonly set:

- `aws_region`
- `instance_type`
- `additional_app_ingress_cidrs` (for direct temporary smoke test access)
- `enable_ssh_ingress`, `ssh_key_name`, `ssh_ingress_cidrs`

## Apply

```bash
cd infra/terraform/aws-single-instance-cloudfront
terraform init
terraform plan
terraform apply
```

One-command workflow after first init:

```bash
terraform apply -auto-approve
```

## Verify deployment

After apply, read outputs:

```bash
terraform output app_url
terraform output cloudfront_domain_name
terraform output ec2_instance_id
terraform output sqlite_ebs_volume_id
```

Smoke checks:

```bash
APP_URL="$(terraform output -raw app_url)"
curl -I "${APP_URL}"
curl -sS "${APP_URL}/feed/daily"
curl -sS "${APP_URL}/swagger-ui/index.html" | head -n 5
```

Confirm EC2 runtime over SSM:

```bash
INSTANCE_ID="$(terraform output -raw ec2_instance_id)"
aws ssm start-session --target "${INSTANCE_ID}"
```

Inside instance:

```bash
sudo systemctl status poe-compose.service
sudo docker ps
sudo docker logs --tail 100 poe-api
df -h /data/poe
```

## Runtime behavior and reboot handling

User-data installs Docker, mounts EBS, writes compose config to `/opt/poe/docker-compose.yml`, and starts `poe-compose.service`.

- Service is enabled at boot (`systemctl enable`)
- App container is recreated on restart via `docker compose up -d`
- SQLite file lives on mounted EBS (`/data/poe/poe.db`) and survives instance reboot

## Caveats and constraints

- This is intentionally single-instance (no autoscaling, no multi-AZ failover).
- CloudFront certificates must be created in `us-east-1`; this stack uses a provider alias for that.
- `origin_subdomain` must be different from `app_subdomain` to avoid CloudFront origin loops.
- EC2 replacement can change public DNS; Route53 origin CNAME is managed by Terraform, so re-apply after replacement.
- Default behavior disables caching for dynamic routes to avoid stale API/UI responses.

## Common recovery commands

Force app restart on instance:

```bash
sudo systemctl restart poe-compose.service
sudo docker ps
```

Re-run user-data script manually (if needed for break/fix):

```bash
sudo bash /var/lib/cloud/instance/scripts/part-001
```

Reconcile drift:

```bash
cd infra/terraform/aws-single-instance-cloudfront
terraform plan
terraform apply
```
