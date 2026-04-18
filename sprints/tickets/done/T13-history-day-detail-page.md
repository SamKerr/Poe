# T13 - History day detail page

## Description

Render poems for a selected historical day.

## Implementation notes

- Route: `/history/{day}`
- Validate day format (`YYYY-MM-DD`)
- Fetch poems for requested day using existing day feed logic
- Handle valid-empty day and invalid day cases gracefully

## Acceptance criteria

- Selecting a history day shows that day's poems
- Invalid day format returns user-friendly error page/response
- Valid day with no poems shows empty state

## Dependencies

T10, T12
