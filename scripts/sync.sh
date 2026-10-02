#!/usr/bin/env bash
# Force an immediate pull-mirror sync. Usage: sync.sh <owner/repo>
set -euo pipefail
cd "$(dirname "$0")/.."

set -a; [ -f .env ] && . ./.env; set +a

: "${GITEA_ROOT_URL:?set GITEA_ROOT_URL in .env}"
: "${GITEA_ADMIN_USER:=gitea}"
: "${GITEA_ADMIN_PASSWORD:?set GITEA_ADMIN_PASSWORD in .env}"

repo="${1:?usage: sync.sh <owner/repo>}"
ROOT="${GITEA_ROOT_URL%/}"

curl -fsS -o /dev/null -w "sync requested for $repo -> HTTP %{http_code}\n" \
  -X POST \
  -u "$GITEA_ADMIN_USER:$GITEA_ADMIN_PASSWORD" \
  "$ROOT/api/v1/repos/$repo/mirror-sync"
