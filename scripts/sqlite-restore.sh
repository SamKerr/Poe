#!/usr/bin/env bash

set -euo pipefail

print_usage() {
  cat <<'EOF'
Usage:
  sqlite-restore.sh [options]

Restore a SQLite database file from a backup copy.

Safety defaults:
  - Does not run stop/start commands unless --run-hooks is provided.
  - Creates a pre-restore copy of the current target DB when it exists.

Options:
  -b, --backup-file PATH     Backup file to restore (.db or .db.gz). Required.
  -t, --target PATH          Target SQLite database file path.
                             Default: derived from SQLITE_DB_PATH or SQLITE_DATASOURCE_URL.
      --pre-hook-cmd CMD     Command to stop services before restore (guidance hook).
      --post-hook-cmd CMD    Command to start services after restore (guidance hook).
      --run-hooks            Execute hook commands. Without this flag, hooks are only printed.
      --owner USER[:GROUP]   Set file owner after restore (requires permissions).
      --mode MODE            Restored DB file mode in octal. Default: 640
      --skip-pre-backup      Do not create a .pre-restore backup of current target DB.
  -h, --help                 Show this help text.

Examples:
  ./scripts/sqlite-restore.sh --backup-file ./db/sqlite-backups/poe-20260418T120000Z.db
  ./scripts/sqlite-restore.sh --backup-file ./db/sqlite-backups/poe-20260418T120000Z.db.gz \
    --target /mnt/poe-data/poe.db --pre-hook-cmd "systemctl stop poe-api" \
    --post-hook-cmd "systemctl start poe-api" --run-hooks
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

default_target_path() {
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

BACKUP_FILE=""
TARGET_DB="$(default_target_path)"
PRE_HOOK_CMD=""
POST_HOOK_CMD=""
RUN_HOOKS="false"
OWNER_SPEC=""
FILE_MODE="640"
SKIP_PRE_BACKUP="false"

while (($# > 0)); do
  case "$1" in
    -b|--backup-file)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      BACKUP_FILE="$2"
      shift 2
      ;;
    -t|--target)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      TARGET_DB="$2"
      shift 2
      ;;
    --pre-hook-cmd)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      PRE_HOOK_CMD="$2"
      shift 2
      ;;
    --post-hook-cmd)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      POST_HOOK_CMD="$2"
      shift 2
      ;;
    --run-hooks)
      RUN_HOOKS="true"
      shift
      ;;
    --owner)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      OWNER_SPEC="$2"
      shift 2
      ;;
    --mode)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      FILE_MODE="$2"
      shift 2
      ;;
    --skip-pre-backup)
      SKIP_PRE_BACKUP="true"
      shift
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

[[ -n "${BACKUP_FILE}" ]] || fail "--backup-file is required."
[[ -f "${BACKUP_FILE}" ]] || fail "Backup file does not exist: ${BACKUP_FILE}"
[[ -r "${BACKUP_FILE}" ]] || fail "Backup file is not readable: ${BACKUP_FILE}"

if [[ ! "${FILE_MODE}" =~ ^[0-7]{3,4}$ ]]; then
  fail "--mode must be a valid octal mode (e.g. 640 or 0640)."
fi

target_dir="$(dirname "${TARGET_DB}")"
mkdir -p "${target_dir}"
[[ -w "${target_dir}" ]] || fail "Target directory is not writable: ${target_dir}"

if [[ -n "${PRE_HOOK_CMD}" ]]; then
  if [[ "${RUN_HOOKS}" == "true" ]]; then
    echo "Running pre-restore hook: ${PRE_HOOK_CMD}"
    bash -c "${PRE_HOOK_CMD}"
  else
    echo "Pre-restore hook configured (not executed): ${PRE_HOOK_CMD}"
    echo "Run with --run-hooks to execute automatically."
  fi
fi

if [[ -f "${TARGET_DB}" && "${SKIP_PRE_BACKUP}" != "true" ]]; then
  pre_backup_path="${TARGET_DB}.pre-restore-$(date -u +%Y%m%dT%H%M%SZ)"
  cp -f "${TARGET_DB}" "${pre_backup_path}"
  chmod "${FILE_MODE}" "${pre_backup_path}" || true
  echo "Pre-restore safety copy created: ${pre_backup_path}"
fi

tmp_restore="$(mktemp "${target_dir}/.restore-XXXXXX.db")"
cleanup_tmp() {
  rm -f "${tmp_restore}"
}
trap cleanup_tmp EXIT

if [[ "${BACKUP_FILE}" == *.gz ]]; then
  gzip -dc "${BACKUP_FILE}" > "${tmp_restore}"
else
  cp -f "${BACKUP_FILE}" "${tmp_restore}"
fi

if command -v sqlite3 >/dev/null 2>&1; then
  integrity="$(sqlite3 "${tmp_restore}" "PRAGMA integrity_check;" || true)"
  if [[ "${integrity}" != "ok" ]]; then
    fail "Integrity check failed on restore candidate: ${integrity}"
  fi
fi

mv -f "${tmp_restore}" "${TARGET_DB}"
chmod "${FILE_MODE}" "${TARGET_DB}"

if [[ -n "${OWNER_SPEC}" ]]; then
  if ! chown "${OWNER_SPEC}" "${TARGET_DB}" 2>/dev/null; then
    fail "Failed to set owner (${OWNER_SPEC}) on ${TARGET_DB}"
  fi
fi

if [[ ! -r "${TARGET_DB}" || ! -w "${TARGET_DB}" ]]; then
  fail "Restored DB does not have required read/write permissions: ${TARGET_DB}"
fi

echo "Restore completed: ${TARGET_DB}"

if [[ -n "${POST_HOOK_CMD}" ]]; then
  if [[ "${RUN_HOOKS}" == "true" ]]; then
    echo "Running post-restore hook: ${POST_HOOK_CMD}"
    bash -c "${POST_HOOK_CMD}"
  else
    echo "Post-restore hook configured (not executed): ${POST_HOOK_CMD}"
    echo "Run with --run-hooks to execute automatically."
  fi
fi
