# Ticket Distribution Plan

This file maps ticket clusters to subagents to enable parallel delivery with minimal conflicts.

## Agent A - Core Publishing

- Epic: `epics/core-publishing/`
- Tickets: `T1`, `T2`, `T3`, `T7`
- Focus: schema, validation, create/read poem API
- Suggested subagent type: `backend-dev`

## Agent B - Mindful Feed

- Epic: `epics/mindful-feed/`
- Tickets: `T5`, `T6`
- Focus: deterministic 10-per-day feed + history
- Suggested subagent type: `backend-dev`

## Agent C - Hardening and Quality

- Epic: `epics/hardening-quality/`
- Tickets: `T4`, `T8`, `T9`
- Focus: anti-pollution checks, tests, docs alignment
- Suggested subagent type: `backend-dev`

## Sequencing note

Parallel start is possible, but merge order should follow:

1. Agent A foundation (`T1`, `T2`, `T3`, `T7`)
2. Agent B feed endpoints (`T5`, `T6`)
3. Agent C guardrails/tests/docs (`T4`, `T8`, `T9`)
