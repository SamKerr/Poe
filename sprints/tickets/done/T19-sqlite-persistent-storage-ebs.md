# T19 - SQLite persistence on EBS volume

## Description

Attach and mount persistent storage for SQLite so data survives redeploys/restarts.

## Implementation notes

- Create and attach EBS volume
- Mount volume at stable path for `poe.db`
- Ensure app datasource points to mounted volume path
- Verify file ownership/permissions

## Acceptance criteria

- SQLite file persists after app restart and instance reboot
- App reads/writes data from mounted volume path
- Storage setup steps are documented

## Dependencies

T18
