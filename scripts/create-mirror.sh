#!/usr/bin/env bash
# Create a pull mirror in Gitea. Usage: create-mirror.sh <git-url> [repo-name] [owner]
set -euo pipefail
cd "$(dirname "$0")/.."

set -a; [ -f .env ] && . ./.env; set +a

: "${GITEA_ROOT_URL:?set GITEA_ROOT_URL in .env}"
: "${GITEA_ADMIN_USER:=gitea}"
: "${GITEA_ADMIN_PASSWORD:?set GITEA_ADMIN_PASSWORD in .env}"

url="${1:?usage: create-mirror.sh <git-url> [repo-name] [owner]}"
name="${2:-$(basename "${url%.git}")}"
owner="${3:-$GITEA_ADMIN_USER}"

case "$url" in
  *github*)                service=github ;;
  *gitlab*)                service=gitlab ;;
  *codeberg*|*forgejo*|*gitea*) service=gitea ;;
  *)                       service=git ;;
esac

ROOT="${GITEA_ROOT_URL%/}"

body=$(printf '{"clone_addr":"%s","repo_name":"%s","repo_owner":"%s","service":"%s","mirror":true,"mirror_interval":"%s","private":false}' \
  "$url" "$name" "$owner" "$service" "${MIRROR_INTERVAL:-10m0s}")

curl -fsS -X POST \
  -u "$GITEA_ADMIN_USER:$GITEA_ADMIN_PASSWORD" \
  -H 'Content-Type: application/json' \
  -d "$body" \
  "$ROOT/api/v1/repos/migrate" >/dev/null

echo "created mirror $owner/$name -> $ROOT/$owner/$name"
