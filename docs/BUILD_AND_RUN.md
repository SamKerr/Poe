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
curl http://localhost:8080/users
curl http://localhost:8080/sqlite
curl http://localhost:8080/sqlite/users
```

Expected:
- `/` returns an `ok` status with DB check
- `/users` returns seeded records
- `/sqlite` returns an `ok` status with SQLite check
- `/sqlite/users` returns seeded SQLite records

## 4) SQLite storage

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
