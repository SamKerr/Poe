# T25 - Domain and TLS with Caddy

## Description

Expose Poe on a custom domain with automatic HTTPS certificates and reverse proxying to the app container.

## Implementation notes

- Add Caddy-based edge service to production compose
- Keep app container private on internal network (no direct public port)
- Document required DNS records for domain cutover
- Include routine validation and renewal checks

## Acceptance criteria

- Domain serves Poe over HTTPS
- HTTP requests redirect to HTTPS
- TLS renewals are managed automatically by Caddy

## Dependencies

T24
