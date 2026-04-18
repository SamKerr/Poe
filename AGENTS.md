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
- Work in sprint methodology: plan sprint first, split execution across subagents, then deliver in verified commit chunks
- Do not overengineer, discuss trade offs and prefer the simplest effective solution. Be pragmatic, sensible and realistic. 
- Stop at sensible, testable commit points, verify the changes so far at each of these stopping points to prove correctness as you go
- Do not change unrelated behavior
- Do not revert any work done by the user, but inspect it and make sure bugs are not introduced

## Sprint workflow

Use this process for multi-step feature work so planning and delivery are consistent.

### Required lifecycle

1. Clarify scope and lock product constraints with the user.
2. Create/update the active sprint plan in `sprints/plans/`:
   - file name format: `sprint-<n>.md` (example: `sprint-2.md`)
   - include scope, ticket list, agent assignment, sequencing, and done criteria
   - use `sprints/plans/sprint-template.md` as the baseline
3. Create or update sprint ticket files in `sprints/tickets/`:
   - one file per active ticket (`Txx-...md`)
   - move completed ticket files into `sprints/tickets/done/`
4. Split sprint scope across subagents with clear ownership boundaries to avoid overlap.
5. Implement sprint scope in sensible commit points (small, coherent chunks).
6. Verify each commit chunk before moving to the next one:
   - run relevant tests/checks
   - confirm expected behavior for changed endpoints/flows
   - fix regressions immediately before continuing
7. After all chunks pass verification, complete the sprint scope.
8. When a sprint is complete, move its sprint plan file:
   - `sprints/plans/sprint-<n>.md` -> `sprints/plans/done/sprint-<n>.md`
9. Keep active-only items in:
   - `sprints/plans/` for active sprint plans
   - `sprints/tickets/` for active ticket files
10. Keep completed-only items in:
   - `sprints/plans/done/` for completed sprint plans
   - `sprints/tickets/done/` for completed ticket files
11. Update docs whenever commands, behavior, or process changes.

## How to verify changes

- Build: `cd poe && ./mvnw clean install`
- Run stack when needed: `./start-app.sh` (or `./start-app.sh --build`)
- Validate endpoints you expect to have changed, eg:
  - `curl http://localhost:8080/poems/1`
  - `curl http://localhost:8080/feed/daily`
  - `curl http://localhost:8080/feed/daily/2026-03-15`
  - open `http://localhost:8080/` and `http://localhost:8080/history`

## Safety

- Keep docs/scripts updated when commands or behavior change
