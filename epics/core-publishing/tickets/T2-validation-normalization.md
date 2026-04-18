# T2 - Input validation and normalization

## Description

Create a central validation/normalization flow for plain-text poem submissions.

## Implementation notes

- Enforce max length `<= 2000` characters
- Reject empty or whitespace-only content
- Normalize line endings
- Trim leading/trailing whitespace while preserving poem body formatting
- Produce stable normalized text for duplicate detection hash

## Acceptance criteria

- Boundary cases are covered (`0`, `1`, `2000`, `2001` chars)
- Invalid payloads return structured `400` responses
- Stored content remains plain text and readable as authored

## Estimate

3 points

## Dependencies

T1
