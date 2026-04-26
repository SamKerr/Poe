# T26 - Backup automation and restore drill

## Description

Automate SQLite backups on the Oracle VM and define a tested restore drill for personal operations.

## Implementation notes

- Reuse `scripts/sqlite-backup.sh` for scheduled backups
- Add helper script to install/update backup cron configuration
- Define retention defaults and backup directory conventions
- Document a minimal restore drill with service stop/start hooks

## Acceptance criteria

- Backup schedule is installed and runs successfully
- Backup artifacts are retained according to configured policy
- Restore drill steps are documented and repeatable

## Dependencies

T24
