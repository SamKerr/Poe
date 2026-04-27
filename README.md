<h1>
  <img src="https://poe.sam-kerr.co.uk/poe.webp" alt="Poe header image" width="56" style="vertical-align: middle; margin-right: 8px;" />
  Poe
</h1>

Poetry publishing app with a Spring Boot backend, SQLite persistence, and Docker-based runtime.



Live site: [https://poe.sam-kerr.co.uk](https://poe.sam-kerr.co.uk)

## Repo layout

- `poe/` - backend application code and Maven project
- `docs/` - build/run, deployment, and operations runbooks
- `deploy/oracle/` - production Docker Compose and Caddy config for Oracle VM
- `scripts/` - helper scripts for deploy, smoke tests, and backups
- `sprints/` - sprint plans and ticket history

## Quick start (local)

From repo root:

```bash
cp .env.example .env
./start-app.sh --build
```

Then open:

- `http://localhost:8080/`
- `http://localhost:8080/history`
- `http://localhost:8080/write`

## Production deployment (Oracle Always Free)

Current production path uses Oracle VM + Caddy + Docker Compose.

Primary runbook:

- `docs/ORACLE_ALWAYS_FREE_DEPLOYMENT.md`

Supporting operations docs:

- `docs/SQLITE_PERSISTENCE_AND_BACKUP.md`
- `docs/BUILD_AND_RUN.md`

## Backend details

App-specific development and API details live in:

- `poe/README.md`
