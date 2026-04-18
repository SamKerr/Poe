# T4 - Add lightweight anti-pollution guardrails

## Description

Implement practical anti-spam controls for anonymous poem publishing.

## Implementation notes

- IP-based rate limiting on `POST /poems` (configurable default, e.g. `5/10min`)
- Recent duplicate-content rejection using `normalized_hash`
- Optional honeypot field for simple bot filtering
- Keep checks lightweight and low-maintenance

## Acceptance criteria

- Rate-limited requests return `429`
- Duplicate submissions in configured window are rejected
- Controls are configurable via app properties/env

## Estimate

5 points

## Dependencies

T3
