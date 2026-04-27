# T24 - Oracle VM bootstrap and runtime

## Status

Done

## Description

Prepare an Oracle Always Free VM to run Poe with Docker Compose in a stable single-instance setup.

## Implementation notes

- Defined VM prerequisites (Ubuntu, open ports, SSH key, public IP)
- Added Docker Engine + Compose bootstrap script for VM hosts
- Added persistent host directories for SQLite and runtime data under `/srv/poe`
- Added deploy script to run the production compose stack

## Acceptance criteria

- [x] VM bootstrap steps are reproducible from a fresh host
- [x] Poe services start with Docker Compose on the VM
- [x] App restart policy and boot behavior are documented

## Dependencies

None
