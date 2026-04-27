# T26 - Backup automation and restore drill

## Status

Done

## Description

Automate SQLite backups on the Oracle VM and define a tested restore drill for personal operations.

## Implementation notes

- Reused `scripts/sqlite-backup.sh` for scheduled backups
- Added `scripts/oracle-install-backup-cron.sh` to install/update backup schedule
- Set retention defaults and backup directory conventions under `/srv/poe/backups`
- Documented manual restore drill flow in Oracle runbook

## Acceptance criteria

- [x] Backup schedule is installed and runs successfully
- [x] Backup artifacts are retained according to configured policy
- [x] Restore drill steps are documented and repeatable

## Dependencies

T24
