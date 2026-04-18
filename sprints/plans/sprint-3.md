# Sprint 3 - CloudFront single-instance deployment

## Goal

Deploy the Poe site behind CloudFront using a single app instance with persistent SQLite storage and tested backup/restore.

## Confirmed product and ops constraints

- Single app instance is acceptable for this phase
- SQLite remains the active database for this sprint
- Data durability is required via persistent storage and backups
- CloudFront is required as public entrypoint
- Keep implementation principled but simple

## Scope (tickets)

- T17: Cloud architecture and IaC plan
- T18: EC2 runtime and app deploy
- T19: SQLite persistent storage on EBS
- T20: CloudFront origin and caching configuration
- T21: SQLite backup and restore workflow
- T22: Security and operational hardening
- T23: Cloud smoke tests and deployment docs

## Agent assignment plan

### Agent A - Platform and infrastructure

- Scope: T17, T18, T20
- Suggested subagent type: `platform-developer`

### Agent B - Data durability and operations

- Scope: T19, T21
- Suggested subagent type: `platform-developer`

### Agent C - Security, validation, and docs

- Scope: T22, T23
- Suggested subagent type: `security-engineer`

## Sequencing

1. Agent A establishes deployable infrastructure and CloudFront path.
2. Agent B lands persistent SQLite storage and backup/restore workflow.
3. Agent C hardens access/ops and completes smoke tests + docs.

## Done criteria

- [ ] CloudFront serves the app over HTTPS
- [ ] App runs in single-instance mode on cloud host
- [ ] SQLite persists across restart/redeploy
- [ ] Backup and restore are tested successfully
- [ ] Smoke tests pass through CloudFront endpoint
- [ ] Deployment and rollback docs are complete
- [ ] Sprint moved to `sprints/plans/done/`
