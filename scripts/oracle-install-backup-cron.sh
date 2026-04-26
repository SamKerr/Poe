#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or via sudo)." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_SCRIPT="${ROOT_DIR}/scripts/sqlite-backup.sh"

if [[ ! -f "${BACKUP_SCRIPT}" ]]; then
  echo "Backup script is missing: ${BACKUP_SCRIPT}" >&2
  exit 1
fi

DB_PATH="${DB_PATH:-/srv/poe/sqlite-data/poe.db}"
BACKUP_DIR="${BACKUP_DIR:-/srv/poe/backups}"
KEEP_COUNT="${KEEP_COUNT:-48}"
LABEL="${LABEL:-poe-oracle}"
CRON_FILE="/etc/cron.d/poe-sqlite-backup"
CRON_SCHEDULE="${CRON_SCHEDULE:-17 * * * *}"

mkdir -p "${BACKUP_DIR}"

cat >"${CRON_FILE}" <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# SQLite backup every hour at minute 17 by default.
${CRON_SCHEDULE} root SQLITE_DB_PATH="${DB_PATH}" /bin/bash "${BACKUP_SCRIPT}" --backup-dir "${BACKUP_DIR}" --label "${LABEL}" --compress --keep "${KEEP_COUNT}" >> /var/log/poe-sqlite-backup.log 2>&1
EOF

chmod 0644 "${CRON_FILE}"

echo "Installed cron schedule at ${CRON_FILE}: ${CRON_SCHEDULE}"
echo "Database: ${DB_PATH}"
echo "Backup dir: ${BACKUP_DIR}"
echo "Retention count: ${KEEP_COUNT}"
echo
echo "Run once now to validate:"
echo "  SQLITE_DB_PATH=\"${DB_PATH}\" /bin/bash \"${BACKUP_SCRIPT}\" --backup-dir \"${BACKUP_DIR}\" --label \"${LABEL}\" --compress --keep \"${KEEP_COUNT}\""
