# Sprint 4 - Oracle Always Free personal deployment

## Goal

Deploy Poe on Oracle Cloud Always Free using Docker Compose with a custom domain, automatic TLS, and scheduled SQLite backups.

## Confirmed product and ops constraints

- Personal-use deployment with low/no recurring cost
- Single VM is acceptable for this phase
- SQLite remains the active database
- Domain + HTTPS are required
- Keep setup simple enough for one-person operations

## Scope (tickets)

- T24: Oracle VM bootstrap and container runtime
- T25: Domain and TLS edge via Caddy
- T26: SQLite backup automation and restore drill
- T27: Oracle deployment smoke tests and runbooks

## Agent assignment plan

### Agent A - Platform bootstrap

- Scope: T24
- Suggested subagent type: `platform-developer`

### Agent B - Edge and security baseline

- Scope: T25
- Suggested subagent type: `security-engineer`

### Agent C - Durability and docs

- Scope: T26, T27
- Suggested subagent type: `platform-developer`

## Sequencing

1. Land Oracle VM bootstrap + production compose runtime.
2. Configure domain routing and automatic TLS termination.
3. Add backup automation, smoke checks, and operator runbooks.

## Done criteria

- [x] Oracle VM can run Poe via Docker Compose
- [x] Domain resolves to VM and serves HTTPS successfully
- [x] SQLite data persists across service restart and VM reboot
- [x] Scheduled backup job is configured and tested
- [x] Restore workflow is documented and validated
- [x] Docs cover deploy, verify, operate, and recover

## Delivery notes

- Production endpoint is live at `https://poe.sam-kerr.co.uk`.
- Restore drill and reboot drill were explicitly deferred by owner decision and accepted for this sprint close.
