# T23 - Cloud smoke tests and deployment docs

## Description

Validate end-to-end deployment and update docs with deploy/verify/rollback instructions.

## Implementation notes

- Smoke test checklist:
  - home/history/write pages through CloudFront
  - API endpoints through CloudFront
  - publish flow persists across restart
- Document:
  - deployment steps
  - verification steps
  - backup/restore validation
  - rollback procedure

## Acceptance criteria

- Cloud smoke tests pass
- Docs are complete enough for another engineer to execute
- Single-instance SQLite limitations are clearly documented

## Dependencies

T17, T18, T19, T20, T21, T22
