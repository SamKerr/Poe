# Poe API

`poe/` contains the Spring Boot backend service for Poe.

Current product model is intentionally simple:

- Anonymous publishing (no auth/account model)
- Plain-text poems only
- `content` hard limit of 2000 characters
- Shared daily feed capped at 30 poems for a given UTC day
- History is browsed by requesting a specific day (no infinite timeline)

## Tech stack

- Java + Spring Boot
- Maven wrapper (`./mvnw`)
- SQLite (primary local database)
- Docker Compose for local stack orchestration

## Run with Docker Compose

From repository root:

1. `cp .env.example .env`
2. `docker compose -f docker-compose.yml up -d --build`
3. `docker compose -f docker-compose.yml logs -f poe-api`

## Build locally (no global Maven install)

From `poe/`:

- `./mvnw clean install`

## API docs (Swagger)

Once the app is running locally:

- OpenAPI JSON: `http://localhost:8080/v3/api-docs`
- Swagger UI: `http://localhost:8080/swagger-ui/index.html`

### Quick start script

From repository root:

- `./start-app.sh`
- `./start-app.sh --build` (force rebuild)

The script will try to start Docker Desktop on macOS, wait for Docker to be ready, create `.env` from `.env.example` if missing, then run the compose stack.

## Verify app and UI

1. Open UI pages in a browser:
   - `http://localhost:8080/` (today's poems)
   - `http://localhost:8080/history` (days with poems)
   - `http://localhost:8080/write` (publish a poem)

2. Verify API endpoints:
   - Create a poem:
     - `curl -X POST http://localhost:8080/poems -H "Content-Type: application/json" -d '{"content":"first line\nsecond line"}'`
   - Fetch by id:
     - `curl http://localhost:8080/poems/1`
   - Daily feed (today UTC):
     - `curl http://localhost:8080/feed/daily`
   - Feed for a specific UTC day:
     - `curl http://localhost:8080/feed/daily/2026-03-15`

## API behavior and constraints

### `POST /poems`

- Accepts JSON body with `content` string
- Normalizes line breaks to `\n` and trims outer whitespace
- Rejects null/blank content
- Rejects content over 2000 characters
- Returns `201 Created` with poem payload

### Guardrails on `POST /poems`

- IP rate limit guard (from `X-Forwarded-For` first value, fallback to remote addr):
  - Default `5` requests / `10` minutes per IP
- Duplicate-content guard:
  - Rejects same normalized content hash submitted in configured recent window
  - Default window `24` hours
- Daily cap guard:
  - Rejects new submissions once `30` poems have been published for the current UTC day

Config is controlled through properties/env vars:

- `poems.guardrails.rate-limit.max-requests` (`POEMS_GUARDRAILS_RATE_LIMIT_MAX_REQUESTS`, default `5`)
- `poems.guardrails.rate-limit.window` (`POEMS_GUARDRAILS_RATE_LIMIT_WINDOW`, default `PT10M`)
- `poems.guardrails.duplicate-window` (`POEMS_GUARDRAILS_DUPLICATE_WINDOW`, default `PT24H`)

### Structured error responses

Errors are returned as:

- `{"error":{"code":"...","message":"...","retryAt":"..."}}`

`retryAt` is populated for rate-limit responses (`429`) and null for other error classes.

## Database connection values in container

- SQLite JDBC URL is read from `SQLITE_DATASOURCE_URL` in `.env`
- Default SQLite file path in container: `/app/data/poe.db`
