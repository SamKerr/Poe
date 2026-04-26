#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or via sudo)." >&2
  exit 1
fi

POE_USER="${POE_USER:-${SUDO_USER:-ubuntu}}"

echo "Updating apt package index..."
apt-get update -y

echo "Installing Docker and Compose plugin..."
apt-get install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
chmod a+r /etc/apt/keyrings/docker.gpg

ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable
EOF

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Preparing runtime directories..."
install -d -m 0755 /srv/poe/sqlite-data
install -d -m 0755 /srv/poe/backups
install -d -m 0755 /srv/poe/caddy-data
install -d -m 0755 /srv/poe/caddy-config

touch /srv/poe/sqlite-data/poe.db
chmod 0640 /srv/poe/sqlite-data/poe.db

echo "Ensuring Docker starts on boot..."
systemctl enable docker
systemctl restart docker

if id "${POE_USER}" >/dev/null 2>&1; then
  echo "Adding ${POE_USER} to docker group..."
  usermod -aG docker "${POE_USER}" || true
fi

echo "Bootstrap complete."
echo "Log out/in for group changes, then deploy with:"
echo "  DOMAIN=poe.example.com ACME_EMAIL=you@example.com bash ./scripts/oracle-deploy.sh"
