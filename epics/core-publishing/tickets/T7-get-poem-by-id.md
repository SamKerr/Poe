# T7 - Implement poem read by ID endpoint

## Description

Add `GET /poems/{id}` to retrieve a single published poem.

## Implementation notes

- Return poem fields needed by clients (`id`, `content`, `created_at`, `publish_day`)
- Follow consistent error format for missing resources

## Acceptance criteria

- Existing poem returns `200`
- Unknown poem ID returns `404`
- Response format is documented and test-covered

## Estimate

2 points

## Dependencies

T1
