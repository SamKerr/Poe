# Cloud Security and Ops Minimums

This runbook defines practical minimum controls for the Sprint 3 single-instance deployment behind CloudFront.

## Scope and assumptions

- One public entry point: CloudFront distribution over HTTPS.
- One app instance (EC2) running Poe and SQLite on attached EBS.
- Backups are taken off-instance (for example to S3) and restore has been tested.
- Team wants simple controls that are easy to operate, not enterprise-heavy patterns.

## Minimum security group rules

Use separate security groups for CloudFront-facing app traffic and operator access.

### App instance security group (`poe-app-sg`)

- **Inbound**
  - `TCP 80` from CloudFront origin-facing sources only (preferred: AWS managed prefix list for CloudFront origin-facing IP ranges).
  - `TCP 443` only if TLS terminates on the instance (otherwise do not open).
  - No wide-open inbound rules (`0.0.0.0/0`) except where explicitly unavoidable.
- **Outbound**
  - Allow `TCP 443` to required AWS APIs/services (CloudWatch, S3, package repos as needed).
  - Allow `UDP/TCP 53` for DNS resolution if using VPC resolver.
  - Restrict broad egress where practical, but do not block required backup/monitoring paths.

### Operator security group (`poe-ops-sg`, optional but recommended)

- **Inbound**
  - `TCP 22` from fixed admin CIDR(s) only (never open SSH to all internet).
- **Outbound**
  - Standard admin workstation egress.

### Rule hygiene

- Tag each rule with owner + reason.
- Remove temporary debug exceptions within the same change window.
- Re-review ingress/egress after each infrastructure change.

## IAM least privilege guidance

Use IAM roles, not long-lived static credentials on the instance.

### Instance role minimums

- CloudWatch Logs:
  - `logs:CreateLogStream`
  - `logs:PutLogEvents`
  - `logs:DescribeLogStreams`
- CloudWatch metrics/alarms integration (if agent used):
  - `cloudwatch:PutMetricData`
- Backup storage access (scoped to one bucket/prefix):
  - `s3:PutObject`
  - `s3:GetObject`
  - `s3:ListBucket` (restricted to backup prefix)
  - Optional safety: `s3:AbortMultipartUpload`

### Guardrails

- Scope resources explicitly (specific log groups, specific S3 bucket/prefix).
- Deny privilege escalation paths:
  - No wildcard `iam:*`
  - No role pass/assume permissions unless explicitly required.
- Rotate any break-glass credentials and keep them out of repo/history.

## Logging and monitoring minimum alarms

These are minimum production-like signals for a single-instance system.

### Logs to retain

- App stdout/stderr (include request path, response code, and error details without sensitive payloads).
- Deployment logs (image/version, start time, migration result).
- Backup logs (start/end time, artifact path, size, success/failure).

### Minimum alarms

- **EC2 instance status check failed** (`StatusCheckFailed_Instance > 0` for 5 minutes).
- **CloudFront 5xx increase** (for example `5xxErrorRate > 1%` for 5 minutes).
- **Origin/app 5xx increase** (app-level 5xx count threshold appropriate for baseline traffic).
- **Disk pressure on data volume** (for example free space < 20%).
- **Backup job failure or stale backup age** (latest successful backup older than expected RPO).

### Alert routing

- Route alarms to one on-call channel (email/Slack/Pager target).
- Every alert includes: system, severity, first seen, and link to dashboard/log group.

## Incident triage checklist

Use this checklist for first-response handling.

1. Confirm impact scope
   - Is issue global or intermittent?
   - Which paths fail: `/`, `/history`, `/write`, `/feed/daily`, `/v3/api-docs`?
2. Check edge and origin health
   - CloudFront distribution status and error metrics.
   - EC2 instance status checks and service process state.
3. Check storage and durability signals
   - EBS volume attached and writable.
   - SQLite file present and recent write timestamps update.
4. Check recent changes
   - Last deploy version, config changes, SG/IAM changes, backup/restore actions.
5. Apply minimal mitigation
   - Restart app service if unhealthy.
   - Roll back to last known-good release/config if regression suspected.
6. Verify recovery
   - Re-run cloud smoke tests script.
   - Confirm alarms clear and writes persist.
7. Capture follow-up
   - Record timeline, root cause hypothesis, mitigation, and permanent fix action item.

## Operational maintenance minimums

- Keep a single source of truth for current deploy version and rollback target.
- Run smoke tests after each deploy and after rollback.
- Test backup + restore on a regular cadence (at least monthly).
- Document known single-instance limitations:
  - No HA failover
  - Brief downtime possible during restart/deploy
  - SQLite write throughput constraints at higher traffic
