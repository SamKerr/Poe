# T18 - EC2 runtime and app deployment

## Description

Provision a single EC2 host and deploy the app container in a repeatable way.

## Implementation notes

- Provision one instance for app runtime
- Configure Docker runtime and startup service/script
- Expose app on instance for origin traffic
- Configure environment variables and runtime paths

## Acceptance criteria

- App starts on EC2 after reboot
- App is reachable from origin endpoint on expected port
- Deployment/restart steps are documented

## Dependencies

T17
