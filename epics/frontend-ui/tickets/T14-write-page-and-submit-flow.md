# T14 - Write page and poem submit flow

## Description

Add write page with poem form and submission handling.

## Implementation notes

- Route: `GET /write` for form page
- Route: `POST /write` (or controller action) to publish poem
- Reuse existing poem publish service/validation
- On success: redirect to `/`
- On failure: redisplay form with error message and preserved input

## Acceptance criteria

- User can submit a poem from UI
- Success redirects to home page
- Validation errors are visible on write page

## Dependencies

T10
