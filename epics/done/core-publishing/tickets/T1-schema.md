# T1 - Create poem persistence schema

## Description

Add database schema for storing published poems and supporting feed/history selection.

## Implementation notes

- Add table `poems` with:
  - `id`
  - `content`
  - `normalized_hash`
  - `created_at` (UTC timestamp)
  - `publish_day` (UTC date key)
- Add indexes:
  - `publish_day`
  - `created_at`
  - `normalized_hash`

## Acceptance criteria

- Migration applies cleanly on empty DB
- Application can insert and read poem rows
- Indexes exist and are used by intended queries

## Estimate

2 points

## Dependencies

None
