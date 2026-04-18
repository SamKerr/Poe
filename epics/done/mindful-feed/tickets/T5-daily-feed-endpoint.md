# T5 - Implement daily mindful feed endpoint

## Description

Add `GET /feed/daily` that returns up to 10 poems for the current UTC day, identical for all users.

## Implementation notes

- Use UTC to determine the active day
- Return max 10 poems for that `publish_day`
- Deterministic ordering (stable across repeated calls on same day)
- Return metadata (`day`, `count`, `limit`)
- No backfill if fewer than 10 poems exist

## Acceptance criteria

- All clients get same ordered results for a given day
- Endpoint never returns more than 10 items
- Fewer than 10 items are returned as-is when day volume is low

## Estimate

5 points

## Dependencies

T1
