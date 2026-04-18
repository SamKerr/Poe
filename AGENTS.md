# AGENTS.md

## Project

- Playground repo with backend app in `poe/`
- Runs with Docker via `docker-compose.yml` and `start-app.sh`
- Uses SQLite as the primary database
- Main docs: `docs/`

## High-level structure

- `poe/` - Java app code, resources, Maven wrapper
- `docs/` - project docs and run/build guides
- `db/` - database-related files and migration playground
- `.cursor/agents/` - custom subagent definitions

## How to work

- Ask clarifying questions and discuss trade offs before agreeing on a high level plan with the user. Ask before you start the implementation.
- Action the plan, step by step, keeping things simple, scoped and well defined as you go
- Do not overengineer, discuss trade offs and prefer the simplest effective solution. Be pragmatic, sensible and realistic. 
- Stop at sensible, testable commit points, verify the changes so far at each of these stopping points to prove correctness as you go
- Do not change unrelated behavior
- Do not revert any work done by the user, but inspect it and make sure bugs are not introduced
- 

## How to verify changes

- Build: `cd poe && ./mvnw clean install`
- Run stack when needed: `./start-app.sh` (or `./start-app.sh --build`)
- Validate endpoints you expect to have changed, eg:
  - `curl http://localhost:8080/`
  - `curl http://localhost:8080/users`
  - `curl http://localhost:8080/sqlite`
  - `curl http://localhost:8080/sqlite/users`

## Safety

- Keep docs/scripts updated when commands or behavior change
