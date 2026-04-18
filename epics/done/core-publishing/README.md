# Epic: Core Publishing

## Goal

Implement the minimum backend capabilities to publish and read poems.

## Why this exists

This epic establishes the primary product loop: create poem -> persist poem -> read poem.
Without this, mindful feed work has no reliable data source.

## Scope

- Create `poems` persistence schema
- Add normalization and validation for poem input
- Implement anonymous `POST /poems`
- Implement `GET /poems/{id}`

## Out of scope

- Authentication and user ownership
- Drafts
- Edit/delete behavior
- Reactions/likes

## Done when

API supports anonymous publishing and single-poem reads with 2000-character enforcement and clear validation errors.
