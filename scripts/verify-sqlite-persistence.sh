#!/usr/bin/env bash

set -euo pipefail

print_usage() {
  cat <<'EOF'
Usage:
  verify-sqlite-persistence.sh [options]

Verify that a SQLite file remains present and readable across a restart event.
If sqlite3 is installed, the script also writes and verifies a probe record.

Options:
  -d, --db-file PATH         SQLite database file path to verify.
                             Default: derived from SQLITE_DB_PATH or SQLITE_DATASOURCE_URL.
  -r, --restart-cmd CMD      Command to run between pre/post checks (optional).
      --probe-table NAME     Probe table name when sqlite3 is available.
                             Default: ops_persistence_probe
      --timeout SEC          Max seconds to wait for DB file after restart. Default: 30
  -h, --help                 Show this help text.

Examples:
  ./scripts/verify-sqlite-persistence.sh
  ./scripts/verify-sqlite-persistence.sh --db-file /mnt/poe-data/poe.db \
    --restart-cmd "docker compose restart poe-api"
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

default_db_path() {
  if [[ -n "${SQLITE_DB_PATH:-}" ]]; then
    printf '%s\n' "${SQLITE_DB_PATH}"
    return
  fi

  if [[ -n "${SQLITE_DATASOURCE_URL:-}" ]]; then
    case "${SQLITE_DATASOURCE_URL}" in
      jdbc:sqlite:*)
        printf '%s\n' "${SQLITE_DATASOURCE_URL#jdbc:sqlite:}"
        return
        ;;
    esac
  fi

  printf '%s\n' "./db/sqlite-data/poe.db"
}

DB_FILE="$(default_db_path)"
RESTART_CMD=""
PROBE_TABLE="ops_persistence_probe"
TIMEOUT_SEC=30

while (($# > 0)); do
  case "$1" in
    -d|--db-file)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      DB_FILE="$2"
      shift 2
      ;;
    -r|--restart-cmd)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      RESTART_CMD="$2"
      shift 2
      ;;
    --probe-table)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      PROBE_TABLE="$2"
      shift 2
      ;;
    --timeout)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      TIMEOUT_SEC="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

if [[ ! "${TIMEOUT_SEC}" =~ ^[0-9]+$ ]]; then
  fail "--timeout must be a non-negative integer."
fi

[[ -f "${DB_FILE}" ]] || fail "Database file not found: ${DB_FILE}"
[[ -r "${DB_FILE}" ]] || fail "Database file is not readable: ${DB_FILE}"

probe_id=""
if command -v sqlite3 >/dev/null 2>&1; then
  probe_id="persist-$(date -u +%Y%m%dT%H%M%SZ)"
  sqlite3 "${DB_FILE}" "CREATE TABLE IF NOT EXISTS ${PROBE_TABLE}(probe_id TEXT PRIMARY KEY, created_at TEXT NOT NULL);"
  sqlite3 "${DB_FILE}" "INSERT INTO ${PROBE_TABLE}(probe_id, created_at) VALUES('${probe_id}', datetime('now'));"
  echo "Probe record inserted: ${probe_id}"
fi

before_size="$(wc -c < "${DB_FILE}")"
echo "Pre-check: file=${DB_FILE} size_bytes=${before_size}"

if [[ -n "${RESTART_CMD}" ]]; then
  echo "Running restart command: ${RESTART_CMD}"
  bash -c "${RESTART_CMD}"
fi

elapsed=0
while [[ ! -f "${DB_FILE}" ]]; do
  if (( elapsed >= TIMEOUT_SEC )); then
    fail "Database file did not reappear within ${TIMEOUT_SEC}s: ${DB_FILE}"
  fi
  sleep 1
  elapsed=$((elapsed + 1))
done

[[ -r "${DB_FILE}" ]] || fail "Database file exists but is not readable after restart: ${DB_FILE}"
after_size="$(wc -c < "${DB_FILE}")"
echo "Post-check: file=${DB_FILE} size_bytes=${after_size}"

if command -v sqlite3 >/dev/null 2>&1; then
  integrity="$(sqlite3 "${DB_FILE}" "PRAGMA integrity_check;" || true)"
  [[ "${integrity}" == "ok" ]] || fail "Integrity check failed after restart: ${integrity}"

  if [[ -n "${probe_id}" ]]; then
    count="$(sqlite3 "${DB_FILE}" "SELECT COUNT(*) FROM ${PROBE_TABLE} WHERE probe_id='${probe_id}';")"
    [[ "${count}" == "1" ]] || fail "Probe row was not found after restart."
    echo "Probe verification passed for ${probe_id}"
  fi
else
  echo "sqlite3 not found; verified file-level persistence only."
fi

echo "Persistence verification passed."
