# T8 - Add integration and unit test coverage

## Description

Add tests to validate core API behavior, edge cases, and anti-pollution controls.

## Implementation notes

- Validation boundaries (`0`, `1`, `2000`, `2001` chars)
- `POST /poems` success and failure paths
- Deterministic daily feed behavior
- History endpoint date and empty-day behavior
- Rate-limit and duplicate guard outcomes

## Acceptance criteria

- Test suite passes via `./mvnw clean install`
- Critical edge cases are covered and reproducible
- API behavior is stable under regression tests

## Estimate

5 points

## Dependencies

T2, T3, T4, T5, T6, T7
