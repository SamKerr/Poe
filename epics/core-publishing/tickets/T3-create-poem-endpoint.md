# T3 - Implement anonymous poem publish endpoint

## Description

Add `POST /poems` to publish poems immediately with no draft state and no auth.

## Implementation notes

- Request payload: `content` (plain text)
- Apply T2 normalization and validation
- Compute/store `normalized_hash`
- Set `publish_day` from current UTC day
- Return created poem resource

## Acceptance criteria

- Valid request returns `201` and created poem payload
- Invalid request returns `400` with predictable error codes
- Endpoint requires no auth and no author fields

## Estimate

3 points

## Dependencies

T1, T2
