# Sprint 2 - Basic Frontend UI

## Goal

Deliver a basic functioning server-rendered UI for the poetry service.

## Confirmed product constraints

- Landing page shows today's poems only (no backfill)
- History page lists only days that have poems
- Selecting a day shows poems from that day
- Write page allows publishing a poem
- Successful publish redirects to home page
- Styling approach: minimal in-app CSS (no Bootstrap for this sprint)

## Scope (tickets)

- T10: UI foundation and template setup
- T11: Landing page for today's poems
- T12: History index page (days with poems only)
- T13: History day detail page
- T14: Write page and poem submit flow
- T15: Minimal CSS and accessibility pass
- T16: UI tests and docs update

## Agent assignment plan

### Agent A - Foundation and history data

- Scope: T10, T12
- Suggested subagent type: `backend-dev`

### Agent B - Read views

- Scope: T11, T13
- Suggested subagent type: `backend-dev`

### Agent C - Write flow, polish, and quality

- Scope: T14, T15, T16
- Suggested subagent type: `backend-dev`

## Sequencing

1. Agent A delivers foundation/routes and history day listing source.
2. Agent B delivers landing and day-detail read pages on top of foundation.
3. Agent C delivers write flow, minimal CSS pass, tests, and docs.

## Done criteria

- [x] Sprint scope implemented
- [x] All pages render and navigate correctly
- [x] Write flow redirects to home on success
- [x] Build/tests pass (`cd poe && ./mvnw clean install`)
- [x] Sprint file moved to `sprints/plans/done/` when complete
