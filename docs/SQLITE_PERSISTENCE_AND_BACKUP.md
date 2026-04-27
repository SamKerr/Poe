# SQLite Persistence and Backup Operations

This document defines operational practices for SQLite persistence and backup/restore for Poe in single-instance mode, including the active Oracle VM deployment.

## Mount Path Conventions

- App container database path: `/app/data/poe.db`
- Host-side persistent path for local/dev compose: `./db/sqlite-data/poe.db`
- Active Oracle host path: `/srv/poe/sqlite-data/poe.db`
- Active Oracle backup path: `/srv/poe/backups`

Set the runtime datasource path with `SQLITE_DATASOURCE_URL`:

```bash
SQLITE_DATASOURCE_URL=jdbc:sqlite:/srv/poe/sqlite-data/poe.db
```

### Ownership and Permissions

- Ensure the parent directory exists before service start.
- Ensure the runtime user can read and write `poe.db`.
- Recommended DB file mode for runtime: `640`.
- Current deployed host uses root-owned paths under `/srv/poe`; manual backup/restore is typically run with `sudo`.

## Scripts

All scripts are in `scripts/` and are safe, parameterized Bash utilities:

- `sqlite-backup.sh`: timestamped backup copy with optional gzip compression and optional retention trimming.
- `sqlite-restore.sh`: restore from `.db` or `.db.gz` with optional pre/post service hook commands.
- `verify-sqlite-persistence.sh`: validates file persistence and (if `sqlite3` exists) validates DB integrity plus a probe row across restart.
- `oracle-install-backup-cron.sh`: installs/updates a cron schedule for recurring backups on Oracle VM hosts.

Use `--help` on each script for current options and examples.

## Backup Frequency Recommendations

Minimum baseline for single-instance SQLite:

- Hourly backups retained for 24 hours.
- Daily backups retained for 14 to 30 days.
- Take an on-demand backup immediately before deploys or maintenance.

Generic example (hourly compressed backup with rolling retention of 24 files):

```bash
./scripts/sqlite-backup.sh \
  --source /srv/poe/sqlite-data/poe.db \
  --backup-dir /var/backups/poe \
  --compress \
  --keep 24 \
  --label poe-hourly
```

Oracle VM default automation example (hourly schedule):

```bash
sudo DB_PATH=/srv/poe/sqlite-data/poe.db \
  BACKUP_DIR=/srv/poe/backups \
  KEEP_COUNT=48 \
  bash ./scripts/oracle-install-backup-cron.sh
```

Immediate validation on Oracle VM:

```bash
sudo SQLITE_DB_PATH="/srv/poe/sqlite-data/poe.db" /bin/bash "./scripts/sqlite-backup.sh" \
  --backup-dir "/srv/poe/backups" \
  --label "poe-oracle" \
  --compress \
  --keep "48"
```

## Restore Test Procedure

Run restore tests regularly in a non-production environment and after any script changes.

1. Create a fresh backup from the active DB.
2. Stop the app service or ensure no writes are in progress.
3. Restore to a test target DB file (or dedicated test environment path).
4. Run `verify-sqlite-persistence.sh` with a restart command to validate survival across service restart.
5. Run app/API smoke checks to confirm read/write correctness.

Example restore flow:

```bash
./scripts/sqlite-restore.sh \
  --backup-file /var/backups/poe/poe-hourly-20260418T120000Z.db.gz \
  --target /srv/poe/sqlite-data/poe.db \
  --pre-hook-cmd "systemctl stop poe-api" \
  --post-hook-cmd "systemctl start poe-api" \
  --run-hooks

./scripts/verify-sqlite-persistence.sh \
  --db-file /srv/poe/sqlite-data/poe.db \
  --restart-cmd "systemctl restart poe-api"
```

## Limitations and Assumptions

SQLite in this deployment model has important characteristics:

- Single-instance write coordination is file-lock based; high write concurrency is limited.
- Restores must be performed with writes stopped to avoid file-level corruption risk.
- Backups done by file copy are point-in-time snapshots; if writes are active, consistency risk increases.
- Recovery objectives depend on backup frequency and retention windows (RPO/RTO should be documented per environment).

For this sprint scope, SQLite remains acceptable only for the single-app-instance deployment model.
