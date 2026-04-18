#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${BASE_URL:-${1:-}}"

if [[ -z "${BASE_URL}" ]]; then
  echo "Usage: BASE_URL=https://example.cloudfront.net $0"
  echo "   or: $0 https://example.cloudfront.net"
  exit 2
fi

# Normalize trailing slash so route joins are predictable.
BASE_URL="${BASE_URL%/}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

pass() {
  echo "PASS: $*"
}

fail() {
  echo "FAIL: $*"
  exit 1
}

request_status() {
  local path="$1"
  local expected="$2"
  local label="$3"
  local outfile="${TMP_DIR}/$(echo "${label}" | tr ' /' '__').out"
  local status

  status="$(curl -sS -o "${outfile}" -w "%{http_code}" "${BASE_URL}${path}")" || fail "${label} request failed"
  if [[ "${status}" != "${expected}" ]]; then
    fail "${label} expected ${expected}, got ${status} (${BASE_URL}${path})"
  fi

  pass "${label} returned ${status}"
}

request_contains() {
  local path="$1"
  local expected_status="$2"
  local required_text="$3"
  local label="$4"
  local outfile="${TMP_DIR}/$(echo "${label}" | tr ' /' '__').out"
  local status
  local body

  status="$(curl -sS -o "${outfile}" -w "%{http_code}" "${BASE_URL}${path}")" || fail "${label} request failed"
  if [[ "${status}" != "${expected_status}" ]]; then
    fail "${label} expected ${expected_status}, got ${status} (${BASE_URL}${path})"
  fi

  body="$(<"${outfile}")"
  if [[ "${body}" != *"${required_text}"* ]]; then
    fail "${label} missing expected content: ${required_text}"
  fi

  pass "${label} returned ${status} and included expected content"
}

echo "Running cloud smoke tests against ${BASE_URL}"

request_status "/" "200" "home page"
request_status "/history" "200" "history page"
request_status "/write" "200" "write page"
request_contains "/feed/daily" "200" "\"items\"" "daily feed api"
request_contains "/v3/api-docs" "200" "\"openapi\"" "openapi docs"
request_status "/swagger-ui/index.html" "200" "swagger ui"

MARKER="smoke-$(date +%s)-$RANDOM"
CREATE_BODY="{\"content\":\"${MARKER}\"}"
CREATE_OUT="${TMP_DIR}/create_poem.out"
CREATE_STATUS="$(curl -sS -o "${CREATE_OUT}" -w "%{http_code}" \
  -X POST "${BASE_URL}/poems" \
  -H "Content-Type: application/json" \
  -d "${CREATE_BODY}")" || fail "create poem request failed"

if [[ "${CREATE_STATUS}" != "201" ]]; then
  fail "create poem expected 201, got ${CREATE_STATUS}"
fi
pass "create poem returned ${CREATE_STATUS}"

CREATE_JSON="$(tr -d '\n' < "${CREATE_OUT}")"
POEM_ID="$(echo "${CREATE_JSON}" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')"
if [[ -z "${POEM_ID}" ]]; then
  fail "create poem response missing numeric id"
fi
pass "create poem response contained id ${POEM_ID}"

request_contains "/poems/${POEM_ID}" "200" "${MARKER}" "poem lookup"
request_contains "/feed/daily" "200" "${MARKER}" "daily feed persistence check"

echo "All cloud smoke checks passed"
