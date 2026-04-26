# T24 - Oracle VM bootstrap and runtime

## Description

Prepare an Oracle Always Free VM to run Poe with Docker Compose in a stable single-instance setup.

## Implementation notes

- Define VM prerequisites (Ubuntu, open ports, SSH key, static public IP)
- Install Docker Engine + Compose plugin on the VM
- Create persistent host directories for SQLite and runtime data
- Add deploy script to run the production compose stack

## Acceptance criteria

- VM bootstrap steps are reproducible from a fresh host
- Poe services start with Docker Compose on the VM
- App restart policy and boot behavior are documented

## Dependencies

None
