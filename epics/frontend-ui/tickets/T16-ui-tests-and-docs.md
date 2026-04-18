# T16 - UI tests and docs update

## Description

Add test coverage for new UI routes and update docs for running/using the UI.

## Implementation notes

- Add integration tests for:
  - landing page render
  - history index/day pages
  - write flow success and validation error path
- Update docs with UI routes and basic usage

## Acceptance criteria

- `cd poe && ./mvnw clean install` passes with UI tests
- Docs include UI page routes and run notes
- No regressions in existing API behavior

## Dependencies

T11, T12, T13, T14
