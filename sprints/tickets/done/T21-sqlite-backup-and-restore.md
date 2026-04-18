# T21 - SQLite backup and restore workflow

## Description

Implement a reliable backup/restore process for the SQLite database in single-instance mode.

## Implementation notes

- Choose backup method:
  - scheduled EBS snapshots (required)
  - optional SQLite file backup script for faster restore testing
- Define backup frequency and retention
- Write and test restore runbook

## Acceptance criteria

- Backups run on schedule
- Restore procedure is documented and tested
- Recovery objective assumptions are explicit

## Dependencies

T19
