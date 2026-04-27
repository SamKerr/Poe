# T27 - Oracle deployment smoke tests and docs

## Status

Done

## Description

Validate Oracle deployment end-to-end and provide a practical runbook for deploy, verify, and recover operations.

## Implementation notes

- Added Oracle-specific smoke tests script at `scripts/oracle-smoke-tests.sh`
- Validated smoke checks through final HTTPS domain
- Added and updated runbooks in `docs/` to reflect live Oracle setup
- Documented operational constraints, checks, and recovery flow

## Acceptance criteria

- [x] Smoke tests pass through the final HTTPS domain
- [x] Deployment guide is executable by another engineer
- [x] Recovery and rollback steps are clear and actionable

## Dependencies

T24, T25, T26
