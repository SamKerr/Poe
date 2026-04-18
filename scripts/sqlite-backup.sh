#!/usr/bin/env bash

set -euo pipefail

print_usage() {
  cat <<'EOF'
Usage:
  sqlite-backup.sh [options]

Create a timestamped backup copy of a SQLite database file.

Options:
  -s, --source PATH          Source SQLite database file path.
                             Default: derived from SQLITE_DB_PATH or SQLITE_DATASOURCE_URL.
  -d, --backup-dir PATH      Directory to store backups.
                             Default: ./db/sqlite-backups
  -l, --label NAME           Optional label prefix in backup filename.
                             Default: poe
  -c, --compress             Compress output with gzip (.gz).
  -k, --keep COUNT           Keep only the newest COUNT backups for this label.
  -h, --help                 Show this help text.

Examples:
  ./scripts/sqlite-backup.sh
  ./scripts/sqlite-backup.sh --source /mnt/poe-data/poe.db --backup-dir /var/backups/poe
  ./scripts/sqlite-backup.sh --compress --keep 14 --label prod
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

default_source_path() {
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

SOURCE_DB="$(default_source_path)"
BACKUP_DIR="./db/sqlite-backups"
LABEL="poe"
COMPRESS="false"
KEEP_COUNT=""

while (($# > 0)); do
  case "$1" in
    -s|--source)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      SOURCE_DB="$2"
      shift 2
      ;;
    -d|--backup-dir)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      BACKUP_DIR="$2"
      shift 2
      ;;
    -l|--label)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      LABEL="$2"
      shift 2
      ;;
    -c|--compress)
      COMPRESS="true"
      shift
      ;;
    -k|--keep)
      [[ $# -ge 2 ]] || fail "Missing value for $1"
      KEEP_COUNT="$2"
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

[[ -n "${LABEL}" ]] || fail "Label cannot be empty."
[[ -f "${SOURCE_DB}" ]] || fail "Source database does not exist: ${SOURCE_DB}"
[[ -r "${SOURCE_DB}" ]] || fail "Source database is not readable: ${SOURCE_DB}"

if [[ -n "${KEEP_COUNT}" && ! "${KEEP_COUNT}" =~ ^[0-9]+$ ]]; then
  fail "--keep must be a non-negative integer."
fi

mkdir -p "${BACKUP_DIR}"
[[ -d "${BACKUP_DIR}" ]] || fail "Backup directory is not a directory: ${BACKUP_DIR}"
[[ -w "${BACKUP_DIR}" ]] || fail "Backup directory is not writable: ${BACKUP_DIR}"

umask 077

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
base_name="${LABEL}-${timestamp}.db"
tmp_backup="${BACKUP_DIR}/.${base_name}.tmp"
final_backup="${BACKUP_DIR}/${base_name}"

cp -f "${SOURCE_DB}" "${tmp_backup}"

if [[ "${COMPRESS}" == "true" ]]; then
  gzip -f "${tmp_backup}"
  final_backup="${final_backup}.gz"
  mv -f "${tmp_backup}.gz" "${final_backup}"
else
  mv -f "${tmp_backup}" "${final_backup}"
fi

if command -v sqlite3 >/dev/null 2>&1; then
  backup_for_check="${final_backup}"
  tmp_check=""
  if [[ "${final_backup}" == *.gz ]]; then
    tmp_check="$(mktemp "${BACKUP_DIR}/.sqlite-backup-check-XXXXXX.db")"
    gzip -dc "${final_backup}" > "${tmp_check}"
    backup_for_check="${tmp_check}"
  fi

  integrity="$(sqlite3 "${backup_for_check}" "PRAGMA integrity_check;" || true)"
  [[ "${integrity}" == "ok" ]] || fail "Backup created but integrity check failed for ${final_backup}: ${integrity}"

  if [[ -n "${tmp_check}" ]]; then
    rm -f "${tmp_check}"
  fi
fi

if [[ -n "${KEEP_COUNT}" ]]; then
  shopt -s nullglob
  backups=( "${BACKUP_DIR}/${LABEL}-"*.db "${BACKUP_DIR}/${LABEL}-"*.db.gz )
  shopt -u nullglob

  if ((${#backups[@]} > KEEP_COUNT)); then
    mapfile -t backups_sorted < <(printf '%s\n' "${backups[@]}" | sort -r)
    backups_to_trim=( "${backups_sorted[@]:${KEEP_COUNT}}" )
    if ((${#backups_to_trim[@]} > 0)); then
      rm -f "${backups_to_trim[@]}"
    fi
  fi
fi

echo "Backup created: ${final_backup}"
