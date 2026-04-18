# CloudFront Smoke Tests

This guide validates the Sprint 3 deployment through the CloudFront endpoint, including UI, API, and SQLite-backed persistence checks.

## Prerequisites

- CloudFront distribution deployed and serving the app origin.
- App instance healthy and reachable by CloudFront.
- You have shell access on a machine with `bash` and `curl`.
- Smoke script is present at `scripts/cloud-smoke-tests.sh`.

Set the target endpoint:

```bash
export BASE_URL="https://<your-cloudfront-domain>"
```

You can also pass the URL as the first argument to the script.

## Run the smoke script

From repo root:

```bash
chmod +x scripts/cloud-smoke-tests.sh
./scripts/cloud-smoke-tests.sh "$BASE_URL"
```

The script checks:

- UI routes:
  - `/`
  - `/history`
  - `/write`
- API/docs routes:
  - `/feed/daily`
  - `/v3/api-docs`
  - `/swagger-ui/index.html`
- Write/read flow:
  - `POST /poems` creates a unique poem
  - `GET /poems/{id}` returns that poem
  - `GET /feed/daily` includes the new poem marker

## Expected outputs

When healthy, output looks like:

- `PASS` lines for each route check with expected status code.
- `PASS` for poem creation (`201`) and poem lookup (`200`).
- Final line: `All cloud smoke checks passed`.

If any check fails, script exits non-zero and prints `FAIL` with route + status details.

## Failure diagnostics

Use this quick map from symptom to likely cause:

- `/`, `/history`, `/write` fail with 403/404
  - CloudFront behavior/path pattern mismatch
  - Origin path misconfiguration
- API endpoints fail with 502/503
  - App process down or origin unreachable
  - Security group blocking origin traffic
- `POST /poems` fails with 4xx
  - Payload rejected by validation/guardrails
  - Origin not forwarding method/body correctly
- `GET /feed/daily` missing new marker
  - Write path failed silently
  - CloudFront cache behavior too aggressive for dynamic endpoints
  - App write did not persist (SQLite file or volume issue)
- `/v3/api-docs` or Swagger route fails
  - Docs endpoint disabled or wrong context path
  - CloudFront behavior excluding docs routes

## Manual follow-up checks

If script fails, run these directly against CloudFront:

```bash
curl -i "$BASE_URL/"
curl -i "$BASE_URL/feed/daily"
curl -i "$BASE_URL/v3/api-docs"
```

Then check origin/app side:

- Instance health and service status
- App logs around failed request timestamps
- Data volume mount and writable SQLite path
- CloudFront behavior + cache policy for dynamic routes

## Rollback checklist

If smoke checks fail after deployment and quick mitigation does not recover:

1. Identify last known-good app version/config.
2. Roll app back to previous release artifact/config.
3. Restart service and confirm origin health.
4. Re-run `./scripts/cloud-smoke-tests.sh "$BASE_URL"`.
5. Verify latest backups are intact before any restore action.
6. If rollback involves data restore, validate:
   - expected poem count/day feed shape
   - ability to write a new poem after restore
7. Record incident timeline, rollback reason, and follow-up fix.

## Notes on single-instance limits

- A single instance can still have short downtime during restart/deploy.
- SQLite on one node is durable with EBS + backups, but not highly available.
- Keep traffic expectations realistic and monitor write latency/error rates.
