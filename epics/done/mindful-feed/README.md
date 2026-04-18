# Epic: Mindful Feed

## Goal

Deliver a finite, non-addictive discovery model: 10 poems per UTC day for everyone.

## Why this exists

This epic replaces infinite scrolling with a bounded daily reading experience while preserving exploration through day-based history.

## Scope

- `GET /feed/daily` for current UTC day
- `GET /feed/daily/{day}` for historical daily sets
- Deterministic ordering and selection per day
- No backfill from previous days

## Out of scope

- Infinite timeline or cursor feed
- Personalized ranking
- Follower graph

## Done when

Clients can fetch the same finite daily set across users and browse prior day sets with clear date handling.
