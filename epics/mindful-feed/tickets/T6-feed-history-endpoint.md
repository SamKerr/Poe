# T6 - Implement daily feed history endpoint

## Description

Add day-addressable history endpoint for browsing previous daily sets.

## Implementation notes

- Endpoint: `GET /feed/daily/{day}`
- Day format: `YYYY-MM-DD` (UTC day key)
- Reuse deterministic selection/ordering behavior from T5
- Return empty list for valid days with no poems

## Acceptance criteria

- Valid day returns deterministic set for that day
- Invalid day format returns `400`
- Missing-content day returns `200` with empty list + metadata

## Estimate

3 points

## Dependencies

T5
