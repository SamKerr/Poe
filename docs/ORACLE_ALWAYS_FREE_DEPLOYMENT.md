# Oracle Always Free Deployment (Docker Compose + Domain + TLS)

This runbook deploys Poe on a single Oracle Cloud Always Free VM with:

- Docker Compose runtime
- Custom domain
- Automatic HTTPS certificates (Caddy + Let's Encrypt)
- SQLite persistence and scheduled backups

## Architecture

```text
Internet
  |
  v
Domain A record (poe.example.com)
  |
  v
Oracle Public IP (reserved)
  |
  v
Caddy container (80/443, TLS termination)
  |
  v
poe-api container (8080 internal network)
  |
  v
Host path /srv/poe/sqlite-data/poe.db
```

## 1) Oracle Cloud prerequisites

In OCI Console:

1. Create a compute instance in the Always Free shape pool.
   - Recommended image: Ubuntu 22.04 LTS
2. Reserve a public IPv4 and attach it to the instance.
3. Configure VCN security rules:
   - Allow inbound `TCP 80` from `0.0.0.0/0`
   - Allow inbound `TCP 443` from `0.0.0.0/0`
   - Allow inbound `TCP 22` only from your admin IP/CIDR
4. Ensure outbound internet access remains enabled (for package install + ACME).

Cost note: Always Free capacity is not guaranteed in every region. Use quotas and billing alerts to avoid surprises.

## 2) DNS setup

Point your domain to the reserved public IP:

- `A` record: `poe.example.com` -> `<reserved_public_ip>`

Wait for DNS propagation before first TLS issuance.

## 3) VM bootstrap

SSH into the VM, clone this repo, and run bootstrap:

```bash
sudo bash ./scripts/oracle-bootstrap-vm.sh
```

What bootstrap does:

- Installs Docker Engine + Compose plugin
- Enables Docker at boot
- Creates runtime directories under `/srv/poe/`
- Prepares SQLite file path

## 4) Configure and deploy

First deployment creates `deploy/oracle/.env.prod` template:

```bash
bash ./scripts/oracle-deploy.sh
```

Edit `deploy/oracle/.env.prod` and set:

- `DOMAIN` (for example `poe.example.com`)
- `ACME_EMAIL` (certificate notification email)
- Optional image/path overrides as needed

Deploy again:

```bash
bash ./scripts/oracle-deploy.sh
```

## 5) Verify runtime and TLS

Container health:

```bash
docker compose --env-file deploy/oracle/.env.prod -f deploy/oracle/docker-compose.prod.yml ps
docker logs --tail 100 poe-caddy
docker logs --tail 100 poe-api
```

Endpoint checks:

```bash
curl -I https://poe.example.com/
curl -sS https://poe.example.com/feed/daily
```

You should see valid HTTPS responses and app content through Caddy.

## 6) Enable scheduled backups

Install hourly backup cron job (minute 17, keep 48 compressed backups by default):

```bash
sudo bash ./scripts/oracle-install-backup-cron.sh
```

Validate with a one-off backup command printed by the script, then verify output in `/srv/poe/backups`.

## 7) Restore drill (recommended before relying on production data)

1. Pick a backup file from `/srv/poe/backups`.
2. Stop app stack:

```bash
docker compose --env-file deploy/oracle/.env.prod -f deploy/oracle/docker-compose.prod.yml stop poe-api
```

3. Restore:

```bash
./scripts/sqlite-restore.sh \
  --backup-file /srv/poe/backups/<backup-file>.db.gz \
  --target /srv/poe/sqlite-data/poe.db
```

4. Start app:

```bash
docker compose --env-file deploy/oracle/.env.prod -f deploy/oracle/docker-compose.prod.yml start poe-api
```

5. Re-run smoke checks:

```bash
BASE_URL="https://poe.example.com" ./scripts/oracle-smoke-tests.sh
```

## 8) Operations checklist

- Reboot safety: `sudo reboot` then confirm `docker ps` and HTTPS endpoint health
- Deploy update: update image tag in `deploy/oracle/.env.prod`, rerun deploy script
- Observe backup freshness: ensure newest backup timestamp is within expected interval
- Keep Oracle NSG/Security List rules minimal and reviewed

## 9) Known limits (single-instance + SQLite)

- No automatic failover (single VM)
- Brief downtime possible during restart/deploy
- SQLite write throughput is limited for high concurrency
- Backups are local unless you add off-host replication
