#!/usr/bin/env bash
# Create the Gitea admin user inside the running container.
set -euo pipefail
cd "$(dirname "$0")/.."

set -a; [ -f .env ] && . ./.env; set +a

: "${GITEA_ADMIN_USER:=gitea}"
: "${GITEA_ADMIN_PASSWORD:?set GITEA_ADMIN_PASSWORD in .env}"
: "${GITEA_ADMIN_EMAIL:=gitea@example.com}"

docker compose exec -u git gitea gitea admin user create \
  --username "$GITEA_ADMIN_USER" \
  --password "$GITEA_ADMIN_PASSWORD" \
  --email "$GITEA_ADMIN_EMAIL" \
  --admin --must-change-password=false
