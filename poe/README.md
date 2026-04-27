# Poe Backend (`poe/`)

`poe/` contains the Spring Boot backend service for Poe.

Product model:

- Anonymous publishing (no auth/account model)
- Plain-text poems only
- `content` hard limit of 2000 characters
- Shared daily feed capped at 30 poems for a given UTC day
- History is browsed by day (UTC)

## Tech stack

- Java 21 + Spring Boot
- Maven Wrapper (`./mvnw`)
- SQLite

## Build and test

From `poe/`:

```bash
./mvnw clean install
```

## Local runtime (from repo root)

```bash
cp .env.example .env
./start-app.sh
```

Force rebuild:

```bash
./start-app.sh --build
```

## API docs (when app is running)

- OpenAPI JSON: `http://localhost:8080/v3/api-docs`
- Swagger UI: `http://localhost:8080/swagger-ui/index.html`

## API behavior

### `POST /poems`

- Accepts JSON body with `content` string
- Normalizes line breaks to `\n` and trims outer whitespace
- Rejects null/blank content
- Rejects content over 2000 characters
- Returns `201 Created` with poem payload

### Guardrails on `POST /poems`

- IP rate limit guard:
  - Default `5` requests per `10` minutes per IP
- Duplicate-content guard:
  - Rejects same normalized content hash in recent window
  - Default window `24` hours
- Daily cap guard:
  - Rejects submissions after `30` poems for current UTC day

Environment variables:

- `POEMS_GUARDRAILS_RATE_LIMIT_MAX_REQUESTS` (default `5`)
- `POEMS_GUARDRAILS_RATE_LIMIT_WINDOW` (default `PT10M`)
- `POEMS_GUARDRAILS_DUPLICATE_WINDOW` (default `PT24H`)

### Error responses

Errors are structured as:

```json
{"error":{"code":"...","message":"...","retryAt":"..."}}
```

`retryAt` is populated for rate-limit responses (`429`) and null for other error types.

## SQLite runtime path

- SQLite JDBC URL is read from `SQLITE_DATASOURCE_URL`
- Default in-container path: `/app/data/poe.db`
