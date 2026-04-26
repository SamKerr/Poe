# T27 - Oracle deployment smoke tests and docs

## Description

Validate Oracle deployment end-to-end and provide a practical runbook for deploy, verify, and recover operations.

## Implementation notes

- Reuse cloud smoke tests against the final domain
- Add Oracle-specific deployment guide and operator checks
- Include reboot/deploy rollback checks
- Call out single-instance limitations and free-tier caveats

## Acceptance criteria

- Smoke tests pass through the final HTTPS domain
- Deployment guide is executable by another engineer
- Recovery and rollback steps are clear and actionable

## Dependencies

T24, T25, T26
