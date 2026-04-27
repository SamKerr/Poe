# T25 - Domain and TLS with Caddy

## Status

Done

## Description

Expose Poe on a custom domain with automatic HTTPS certificates and reverse proxying to the app container.

## Implementation notes

- Added Caddy-based edge service to production compose
- Kept app container private on internal network (no direct public port mapping)
- Documented DNS record setup and OCI ingress requirements
- Validated HTTPS and HTTP -> HTTPS redirect behavior

## Acceptance criteria

- [x] Domain serves Poe over HTTPS
- [x] HTTP requests redirect to HTTPS
- [x] TLS renewals are managed automatically by Caddy

## Dependencies

T24
