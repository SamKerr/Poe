# T20 - CloudFront origin and caching configuration

## Description

Put CloudFront in front of the single EC2 origin and configure safe cache behavior.

## Implementation notes

- Configure CloudFront origin to EC2 endpoint
- Configure cache behaviors:
  - cache static assets (`/css/*`, similar static paths)
  - disable or minimize caching for dynamic HTML/API routes
- Forward headers/query/cookies only as needed
- Enable HTTPS with ACM cert on distribution domain

## Acceptance criteria

- Site is accessible via CloudFront domain over HTTPS
- Static assets are cached
- Dynamic pages/API are not stale due to over-caching

## Dependencies

T18
