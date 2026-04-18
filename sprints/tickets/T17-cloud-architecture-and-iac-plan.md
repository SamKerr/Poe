# T17 - Cloud architecture and IaC plan

## Description

Define the single-instance AWS architecture for deployment behind CloudFront and create the initial infrastructure plan/config.

## Implementation notes

- Target architecture:
  - CloudFront (public edge)
  - single EC2 origin
  - persistent EBS volume for SQLite
  - Route53 + ACM for domain/TLS
- Decide IaC approach for this sprint (Terraform or CloudFormation) and keep it simple.
- Document networking assumptions (public/private, security groups, ports).

## Acceptance criteria

- Architecture decisions are documented
- IaC scaffolding exists for core resources
- Single-instance constraint is explicitly documented

## Dependencies

None
