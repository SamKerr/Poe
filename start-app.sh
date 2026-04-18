#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="docker-compose.yml"
FORCE_BUILD="false"
ENV_FILE="${ROOT_DIR}/.env"
ENV_EXAMPLE_FILE="${ROOT_DIR}/.env.example"

for arg in "$@"; do
  case "$arg" in
    --build)
      FORCE_BUILD="true"
      ;;
    *)
      COMPOSE_FILE="$arg"
      ;;
  esac
done

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

pick_compose_cmd() {
  if has_cmd docker && docker compose version >/dev/null 2>&1; then
    echo "docker compose"
    return
  fi

  if has_cmd docker-compose; then
    echo "docker-compose"
    return
  fi

  echo ""
}

start_docker_if_needed() {
  if has_cmd docker && docker info >/dev/null 2>&1; then
    return
  fi

  if [[ "${OSTYPE:-}" == darwin* ]]; then
    if [[ -d "/Applications/Docker.app" ]] || [[ -d "$HOME/Applications/Docker.app" ]]; then
      echo "Starting Docker Desktop..."
      open -a Docker || true
    fi
  fi

  echo "Waiting for Docker daemon..."
  for _ in {1..60}; do
    if has_cmd docker && docker info >/dev/null 2>&1; then
      echo "Docker daemon is ready."
      return
    fi
    sleep 2
  done

  echo "Docker daemon did not become ready in time." >&2
  echo "Start Docker Desktop (or Colima) and retry." >&2
  exit 1
}

if [[ ! -f "${ROOT_DIR}/${COMPOSE_FILE}" ]]; then
  echo "Compose file not found: ${COMPOSE_FILE}" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" && -f "${ENV_EXAMPLE_FILE}" ]]; then
  echo "No .env found. Creating from .env.example..."
  cp "${ENV_EXAMPLE_FILE}" "${ENV_FILE}"
fi

start_docker_if_needed

COMPOSE_CMD="$(pick_compose_cmd)"
if [[ -z "${COMPOSE_CMD}" ]]; then
  echo "Neither 'docker compose' nor 'docker-compose' is available." >&2
  exit 1
fi

echo "Using compose command: ${COMPOSE_CMD}"
if [[ "${FORCE_BUILD}" == "true" ]]; then
  ${COMPOSE_CMD} -f "${ROOT_DIR}/${COMPOSE_FILE}" up -d --build
else
  ${COMPOSE_CMD} -f "${ROOT_DIR}/${COMPOSE_FILE}" up -d
fi

echo
echo "Stack started. Helpful checks:"
echo "  ${COMPOSE_CMD} -f \"${ROOT_DIR}/${COMPOSE_FILE}\" ps"
echo "  curl http://localhost:8080/"
echo "  curl http://localhost:8080/users"
