#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/deploy/oracle/docker-compose.prod.yml"
ENV_FILE="${ROOT_DIR}/deploy/oracle/.env.prod"

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "Missing compose file: ${COMPOSE_FILE}" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  cat >"${ENV_FILE}" <<'EOF'
# Required
DOMAIN=poe.example.com
ACME_EMAIL=you@example.com

# Optional
POE_APP_IMAGE=ghcr.io/sam/poe:latest
SQLITE_DATASOURCE_URL=jdbc:sqlite:/app/data/poe.db
POE_SQLITE_DIR=/srv/poe/sqlite-data
POE_CADDY_DATA_DIR=/srv/poe/caddy-data
POE_CADDY_CONFIG_DIR=/srv/poe/caddy-config
EOF
  echo "Created ${ENV_FILE}. Update values and rerun."
  exit 2
fi

echo "Validating required directories..."
mkdir -p /srv/poe/sqlite-data /srv/poe/caddy-data /srv/poe/caddy-config

echo "Starting Oracle production stack..."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d

echo
echo "Deployment complete. Helpful checks:"
echo "  docker compose --env-file \"${ENV_FILE}\" -f \"${COMPOSE_FILE}\" ps"
echo "  docker logs --tail 100 poe-caddy"
echo "  docker logs --tail 100 poe-api"
