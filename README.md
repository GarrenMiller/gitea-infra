# gitea-infra

Self-hosted **Gitea** + **act_runner** used to run GitHub Actions workflows from
repositories that are kept on GitHub and **pull-mirrored** into Gitea. GitHub
stays the source of truth; Gitea provides the CI execution.

```
GitHub repo --push--> GitHub
                         |  periodic git fetch (<= 10m)
                         v
                   Gitea (sqlite) -- job queue --> gitea/runner (act_runner)
                   http://<LAN-IP>:3000                    | mounts host docker.sock
                                                           v
                                                     job container (ubuntu-latest)
```

The application/test repositories live **outside** this repo (e.g.
`../gitea-test-app`). This repo is only the server + runner configuration.

## Services

| Service | Image | Ports | Notes |
|---|---|---|---|
| `gitea` | `gitea/gitea:1` | `3000` (web), `2223` (ssh) | SQLite; Actions enabled, mirror repos get `repo.actions` |
| `runner` | `gitea/runner:latest` | - | Mounts `/var/run/docker.sock`; label `ubuntu-latest:docker://node:20-bookworm` |

The Compose project name is pinned to `gitea` (`name:` in
`docker-compose.yml`) so the data volumes survive directory renames.

## Setup

```sh
cp .env.example .env     # set GITEA_ROOT_URL to this machine's LAN IP
docker compose up -d gitea    # start gitea first
make admin               # create the admin user
make token               # fetch a runner registration token into .env
docker compose up -d runner   # start the runner with the token
```

`GITEA_ROOT_URL` must be reachable **from job containers**, so use the LAN IP,
not `localhost`.

## Use

```sh
# create a pull mirror of a repo (public, or private with a token)
make mirror URL=https://github.com/owner/repo.git

# force a sync now instead of waiting for the interval
make sync REPO=owner/repo

make ps                  # status
make logs                # tail logs
make down                # stop
make nuke                # stop + delete volumes
```

After the mirror exists, push to GitHub and wait up to the mirror interval
(`mirror_interval`, default `10m`, configurable in the repo's Mirror Settings),
or `make sync`. Runs appear under the mirror repo's **Actions** tab.

## Scripts

| Script | Purpose |
|---|---|
| `scripts/create-admin.sh` | create the admin user inside the container |
| `scripts/get-runner-token.sh` | fetch an instance runner token, write it to `.env` |
| `scripts/create-mirror.sh <url> [name] [owner]` | create a pull mirror |
| `scripts/sync.sh <owner/repo>` | force a mirror sync |

## Windows runner

The `runner` service above is Linux-only. To run `windows-latest` jobs, run
`act_runner` natively inside the Windows VM on the host (there is no Windows
container image for it). Register it against this Gitea instance:

```powershell
act_runner.exe register --no-interactive `
  --instance http://<LAN-IP>:3000 `
  --token <RUNNER_TOKEN from make token> `
  --name win11-runner `
  --labels windows-latest
```

Then run it as a service. The VM is on libvirt's NAT network; it reaches Gitea
via the host LAN IP (or `http://192.168.122.1:3000`). Jobs queue if the VM is
not running. Windows jobs execute directly on the VM, so install the toolchains
they need (Git for Windows, PowerShell, etc.).

## Notes

- Mirror repos are read-only in Gitea. A mirror sync emits a **push** event, so
  `on: push` workflows run — but only when the sync actually brings in new
  commits. The initial migration emits a `repository` event and does **not**
  trigger `on: push`, so the first CI run happens on your next push.
- The runner uses the host Docker socket to start job containers; the image is
  selected by the `runs-on` label (`ubuntu-latest:docker://node:20-bookworm`).
- `.env` is gitignored; only `.env.example` is committed.
