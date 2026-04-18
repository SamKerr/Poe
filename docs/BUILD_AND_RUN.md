# Build and Run Guide

This project contains a Spring Boot app in `poe` using SQLite as the primary database.

## Prerequisites

- Docker Desktop running (or Docker daemon via Colima)
- Java 21 installed (for local runs)

You do not need a global Maven install because the project uses Maven Wrapper (`./mvnw`).

## 1) Build the project (local)

From repo root:

```bash
cd poe
./mvnw clean install
```

Download dependency sources for better IDE navigation:

```bash
./mvnw dependency:sources
```

## 2) Run with Docker

From repo root:

```bash
cp .env.example .env   # first time only
./start-app.sh
```

Force a fresh image rebuild:

```bash
./start-app.sh --build
```

## 3) Verify the app is running

```bash
curl http://localhost:8080/
curl http://localhost:8080/sqlite
curl http://localhost:8080/users
curl http://localhost:8080/sqlite/users
```

Expected:
- `/` returns an `ok` status with DB check
- `/sqlite` returns an `ok` status with SQLite check
- `/users` returns seeded records
- `/sqlite/users` returns seeded SQLite records

## 4) Verify poem endpoints

Create a poem:

```bash
curl -X POST http://localhost:8080/poems \
  -H "Content-Type: application/json" \
  -d '{"content":"  first line\r\nsecond line  "}'
```

Expected:
- HTTP `201`
- Response `content` normalized to `first line\nsecond line`

Get a poem by id:

```bash
curl http://localhost:8080/poems/1
```

Daily feed (today in UTC):

```bash
curl http://localhost:8080/feed/daily
```

History/day feed:

```bash
curl http://localhost:8080/feed/daily/2026-03-15
```

Expected:
- Daily/history endpoints return `day`, `count`, `limit`, and `items`
- `limit` is always `10`
- Valid day format is strict `YYYY-MM-DD`

## 5) Guardrail configuration

`POST /poems` has lightweight anti-pollution guardrails:

- Per-IP rate limit, default `5` requests per `10` minutes
- Duplicate-content rejection in recent window, default `24` hours

Environment variables:

- `POEMS_GUARDRAILS_RATE_LIMIT_MAX_REQUESTS` (default `5`)
- `POEMS_GUARDRAILS_RATE_LIMIT_WINDOW` (default `PT10M`)
- `POEMS_GUARDRAILS_DUPLICATE_WINDOW` (default `PT24H`)

Rate-limited requests return HTTP `429` with a structured error payload including `retryAt`.

## 6) OpenAPI and Swagger UI

When the app is running locally:

```bash
open http://localhost:8080/swagger-ui/index.html
curl http://localhost:8080/v3/api-docs
```

Use Swagger UI to execute `POST /poems`, `GET /poems/{id}`, and feed endpoints directly from the browser.

## 7) SQLite storage

- SQLite path defaults to `/app/data/poe.db` inside the app container.
- Docker Compose maps `./db/sqlite-data` from your repo to `/app/data` for persistence.
- Override path via `SQLITE_DATASOURCE_URL` in `.env` if needed.
- SQLite schema/data scripts live in:
  - `poe/src/main/resources/db/sqlite/schema.sql`
  - `poe/src/main/resources/db/sqlite/data.sql`

## IntelliJ setup (for Go to Declaration)

If imports like `@GetMapping` do not resolve:

1. Open `poe/pom.xml`
2. Right-click -> **Add as Maven Project**
3. Set Project SDK to Java 21
4. Reload Maven project

If Maven window is missing:
- Enable Maven plugin in **Settings -> Plugins**
- Re-open `poe` as project root

## Common issues

- **Docker daemon not running**
  - Start Docker Desktop, then re-run `./start-app.sh`.
- **`mvn` command not found**
  - Use `./mvnw` inside `poe` instead of `mvn`.
