# Oracle Always Free Deployment (Docker Compose + Domain + TLS)

This runbook reflects the current production-style setup for this repo:

- Public URL: `https://poe.sam-kerr.co.uk`
- Oracle VM public IP (current): `141.147.119.162`
- Reverse proxy/TLS: Caddy (`caddy:2.8`)
- App image in use: local build (`poe-local:latest`)
- Runtime data path: `/srv/poe/sqlite-data/poe.db`
- Scheduled backups: `/srv/poe/backups` via cron

## Architecture

```text
Internet
  |
  v
DNS A record: poe.sam-kerr.co.uk -> 141.147.119.162
  |
  v
Oracle VM (Always Free)
  |
  v
Caddy container (80/443, TLS + redirect)
  |
  v
poe-api container (internal port 8080)
  |
  v
Host path /srv/poe/sqlite-data/poe.db
```

## 1) Oracle Cloud prerequisites

In OCI Console:

1. Create a compute instance in an Always Free shape.
   - Recommended image: Ubuntu 22.04 LTS
2. Attach a public IPv4.
3. Confirm the VNIC network controls:
   - If using NSG, add ingress rules on the attached NSG.
   - If using Security Lists, add rules there as well.
4. Required inbound rules:
   - `TCP 80` from `0.0.0.0/0`
   - `TCP 443` from `0.0.0.0/0`
   - `TCP 22` from your admin IP/CIDR only
5. Leave source ports as `All` for inbound web rules.

Cost note: Always Free capacity is region-dependent and not guaranteed. Keep billing alerts enabled.

## 2) DNS setup

Create an `A` record:

- `poe.sam-kerr.co.uk` -> `141.147.119.162`

Validate propagation from public resolvers before cert issuance:

```bash
dig +short A poe.sam-kerr.co.uk @1.1.1.1
dig +short A poe.sam-kerr.co.uk @8.8.8.8
```

## 3) VM bootstrap

From the VM:

```bash
git clone https://github.com/SamKerr/Poe.git
cd Poe
sudo bash ./scripts/oracle-bootstrap-vm.sh
```

If `docker` permission errors appear after bootstrap, refresh group membership:

```bash
newgrp docker
```

## 4) Configure and deploy

First run creates `deploy/oracle/.env.prod`:

```bash
bash ./scripts/oracle-deploy.sh
```

Edit `deploy/oracle/.env.prod` with real values:

- `DOMAIN=poe.sam-kerr.co.uk`
- `ACME_EMAIL=<your-email>`

Because GHCR app image access may be restricted, build and use local image:

```bash
docker build -t poe-local:latest ./poe
sed -i 's|^POE_APP_IMAGE=.*|POE_APP_IMAGE=poe-local:latest|' deploy/oracle/.env.prod
```

Deploy:

```bash
bash ./scripts/oracle-deploy.sh
```

## 5) Verify runtime and TLS

```bash
docker compose --env-file deploy/oracle/.env.prod -f deploy/oracle/docker-compose.prod.yml ps
docker logs --tail 100 poe-caddy
docker logs --tail 100 poe-api
```

Check edge behavior:

```bash
curl -I http://poe.sam-kerr.co.uk/
curl -I https://poe.sam-kerr.co.uk/
```

Expected:

- HTTP returns `308` redirect to HTTPS
- HTTPS returns `200`

Run smoke checks:

```bash
BASE_URL="https://poe.sam-kerr.co.uk" bash ./scripts/oracle-smoke-tests.sh
```

## 6) Enable scheduled backups

Install hourly backup job (minute 17, keep 48):

```bash
sudo bash ./scripts/oracle-install-backup-cron.sh
```

Validate immediately:

```bash
sudo SQLITE_DB_PATH="/srv/poe/sqlite-data/poe.db" /bin/bash "./scripts/sqlite-backup.sh" \
  --backup-dir "/srv/poe/backups" \
  --label "poe-oracle" \
  --compress \
  --keep "48"
```

Optional convenience permissions for manual non-sudo backups:

```bash
sudo chgrp ubuntu /srv/poe/sqlite-data /srv/poe/sqlite-data/poe.db /srv/poe/backups
sudo chmod 750 /srv/poe/sqlite-data
sudo chmod 640 /srv/poe/sqlite-data/poe.db
sudo chmod 775 /srv/poe/backups
```

## 7) Restore drill (manual)

Restore is intentionally manual:

1. Stop app writes:

```bash
docker compose --env-file deploy/oracle/.env.prod -f deploy/oracle/docker-compose.prod.yml stop poe-api
```

2. Restore chosen backup:

```bash
./scripts/sqlite-restore.sh \
  --backup-file /srv/poe/backups/<backup-file>.db.gz \
  --target /srv/poe/sqlite-data/poe.db
```

3. Start app:

```bash
docker compose --env-file deploy/oracle/.env.prod -f deploy/oracle/docker-compose.prod.yml start poe-api
```

4. Re-run smoke tests:

```bash
BASE_URL="https://poe.sam-kerr.co.uk" bash ./scripts/oracle-smoke-tests.sh
```

## 8) Operations checklist

- Reboot safety: `sudo reboot`, reconnect, run `docker ps`, then `curl -I https://poe.sam-kerr.co.uk/`
- Deploy update: build new image tag and update `POE_APP_IMAGE` in `deploy/oracle/.env.prod`
- Backup freshness: confirm newest file in `/srv/poe/backups` is within RPO window
- Keep OCI ingress rules tight; remove temporary wide-open SSH rules

## 9) Troubleshooting

- **ACME NXDOMAIN in Caddy logs**
  - DNS not propagated yet; re-check with `dig @1.1.1.1` and `dig @8.8.8.8`
- **ACME timeout on `http-01`**
  - Port 80 ingress blocked in OCI NSG/security lists
- **`permission denied` on Docker socket**
  - Run `newgrp docker` or re-login after bootstrap
- **`error from registry: denied` on GHCR image**
  - Build local image (`poe-local:latest`) and set `POE_APP_IMAGE`
- **Backup script says DB/backups not writable**
  - Use `sudo` for backup/restore operations or adjust group permissions

## 10) Known limits

- Single VM (no automatic failover)
- SQLite write throughput is limited under high concurrency
- Local backups are not off-site by default (add off-host replication for better disaster recovery)
