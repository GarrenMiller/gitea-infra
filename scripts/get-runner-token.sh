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
  | python3 -c 'import sys, json; print(json.load(sys.stdin)["token"])')

echo "$token"

if [ -f .env ] && grep -q '^RUNNER_TOKEN=' .env; then
  TOKEN="$token" python3 - <<'PY'
import os, re
tok = os.environ["TOKEN"]
with open(".env") as fh:
    text = fh.read()
text = re.sub(r"(?m)^RUNNER_TOKEN=.*$", f"RUNNER_TOKEN={tok}", text, count=1)
with open(".env", "w") as fh:
    fh.write(text)
PY
  echo "(updated RUNNER_TOKEN in .env)" >&2
fi
