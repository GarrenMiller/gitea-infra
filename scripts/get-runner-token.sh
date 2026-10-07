#!/usr/bin/env bash
# Fetch an instance-level actions runner registration token and store it in .env.
set -euo pipefail
cd "$(dirname "$0")/.."

set -a; [ -f .env ] && . ./.env; set +a

: "${GITEA_ROOT_URL:?set GITEA_ROOT_URL in .env}"
: "${GITEA_ADMIN_USER:=gitea}"
: "${GITEA_ADMIN_PASSWORD:?set GITEA_ADMIN_PASSWORD in .env}"

ROOT="${GITEA_ROOT_URL%/}"

token=$(curl -fsS -X POST \
  -u "$GITEA_ADMIN_USER:$GITEA_ADMIN_PASSWORD" \
  "$ROOT/api/v1/admin/actions/runners/registration-token" \
  | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

echo "$token"

if [ -f .env ] && grep -q '^RUNNER_TOKEN=' .env; then
  sed -i "s|^RUNNER_TOKEN=.*$|RUNNER_TOKEN=$token|" .env
  echo "(updated RUNNER_TOKEN in .env)" >&2
fi
