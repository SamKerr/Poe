# Poe API - backend service for a poetry social app

`poe/` contains the Spring Boot backend service for Poe: a poetry-first social app.

Think "Twitter clone, but only for poetry":

- users create accounts and manage profiles
- users post short poems instead of general status updates
- the API handles data storage and backend logic for the app

This project currently focuses on the backend service and local developer workflow.

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

### Quick start script

From repository root:

- `./start-app.sh`
- `./start-app.sh --build` (force rebuild)

The script will try to start Docker Desktop on macOS, wait for Docker to be ready, create `.env` from `.env.example` if missing, then run the compose stack.

## Verify app and query DB

1. Check app and database connectivity:
   - `curl http://localhost:8080/`
   - `curl http://localhost:8080/users`
   - `curl http://localhost:8080/sqlite`
   - `curl http://localhost:8080/sqlite/users`

## Database connection values in container

- SQLite JDBC URL is read from `SQLITE_DATASOURCE_URL` in `.env`
- Default SQLite file path in container: `/app/data/poe.db`
