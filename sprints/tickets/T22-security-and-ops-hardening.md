# T22 - Security and operational hardening

## Description

Apply minimum security and reliability controls for a single-instance production-like deployment.

## Implementation notes

- Restrict inbound access via security groups
- Configure app/service logging and basic monitoring alarms
- Set least-privilege IAM for instance and backup actions
- Document maintenance operations (restart, deploy, incident checks)

## Acceptance criteria

- Public exposure is limited to intended entry points
- Logs and basic health signals are available
- Operational runbook covers routine maintenance

## Dependencies

T18, T20, T21
