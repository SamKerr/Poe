# T12 - History index page (days with poems only)

## Description

Create history page that lists only days that have at least one poem.

## Implementation notes

- Route: `/history`
- Add query/service for distinct `publish_day` values
- Sort newest day first
- Render day links to `/history/{day}`

## Acceptance criteria

- History shows only days with poems
- Days are sorted newest-first
- Links navigate to day detail page

## Dependencies

T10
