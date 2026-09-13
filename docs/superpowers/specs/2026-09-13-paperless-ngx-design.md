# Paperless-ngx (Full Stack)

**Date:** 2026-09-13  
**Status:** Approved for implementation planning  
**Stack:** riverdale_server (Docker Compose)

## Goal

Add **Paperless-ngx** as a first-class service in the Riverdale stack: document ingest, OCR, search, and archive, reachable at `paperless.lan`, with documents and DB state on the media disk and nightly copies on the NVMe via the existing backup job. Also add a Homarr app tile once the service is healthy.

## Non-goals

- External HTTPS / public internet exposure (LAN `.lan` only, same as other apps)
- Scanner hardware, SMB/NFS consume shares, or mobile sync clients
- Paperless-AI / GPT add-on containers
- A separate compose project or Docker named volumes for Paperless data
- Offsite/cloud backup (existing local dual-disk model only)

## Context

- Stack today: single `docker-compose.yml`, Traefik `.lan` hosts, WUD labels, configs under `${CONFIG_ROOT}`, data on `/mnt/media-storage`
- No Postgres/Redis services exist yet; Paperless will introduce the first multi-container app group
- Nightly backup: `/home/river/backups/scripts/backup-config.sh` at 03:00 — rsyncs `${CONFIG_ROOT}` → `/home/river/backups/config/` (NVMe) and mirrors compose; also mirrors to `/mnt/media-storage/backups/`
- Homarr is on V2 beta; boards live in SQLite appdata (not a checked-in JSON app list)
- Upstream reference: Paperless `docker-compose.postgres-tika.yml` (webserver + Postgres + Valkey + Gotenberg + Tika)

## Approach (chosen)

**Inline full stack in `docker-compose.yml` with bind mounts + extend existing backups.**

1. Add five services to the main compose file on `riverdale_network`
2. Bind-mount config/DB under `${CONFIG_ROOT}/paperless/` and documents under `/mnt/media-storage/paperless/`
3. Expose UI via Traefik (`paperless.lan`) and a host port from `.env`
4. Extend `backup-config.sh` (+ `RECOVERY.md`) so the document library is copied to NVMe nightly
5. Create dirs via `docker-compose.init.yml`
6. After healthy, add Homarr tile for `http://paperless.lan`

### Alternatives considered

| Option | Summary | Why not |
| :--- | :--- | :--- |
| Separate `docker-compose.paperless.yml` | Isolated project / `-f` merge | Breaks single-stack ops habit |
| Named volumes only | Closer to upstream sample | Harder to rsync/inspect; fights existing backup model |
| SQLite / no Tika-Gotenberg | Fewer containers | User chose full OCR/Office stack (option A) |
| Separate Paperless-only backup cron | Second job on NVMe | Duplicates schedule/log/recovery story |

## Design

### Services

| Container | Image (pin family) | Role |
| :--- | :--- | :--- |
| `paperless` | `ghcr.io/paperless-ngx/paperless-ngx:latest` | Web UI + workers |
| `paperless-db` | `postgres:18` | Database |
| `paperless-redis` | `valkey/valkey:9-alpine` | Redis-compatible broker |
| `paperless-gotenberg` | `gotenberg/gotenberg:8` | Office → PDF |
| `paperless-tika` | `apache/tika:latest` | Content extraction / OCR helper |

`paperless` depends on db, redis, gotenberg, and tika. Only `paperless` publishes a host port and Traefik labels; helpers stay internal to `riverdale_network`.

### Storage layout

**Config / DB (media disk, under CONFIG_ROOT):**

| Host path | Container path |
| :--- | :--- |
| `${CONFIG_ROOT}/paperless/data` | `/usr/src/paperless/data` |
| `${CONFIG_ROOT}/paperless/pgdata` | Postgres data dir (Postgres 18: `/var/lib/postgresql`) |
| `${CONFIG_ROOT}/paperless/redis` | `/data` (Valkey) |

**Documents (media disk, dedicated tree — not under `media/movies|tv`):**

| Host path | Container path |
| :--- | :--- |
| `/mnt/media-storage/paperless/media` | `/usr/src/paperless/media` |
| `/mnt/media-storage/paperless/consume` | `/usr/src/paperless/consume` |
| `/mnt/media-storage/paperless/export` | `/usr/src/paperless/export` |

Use `PUID`/`PGID`/`USERMAP_UID`/`USERMAP_GID` as required by Paperless so consume/media are writable by the host user.

### Environment / secrets

Add to `.env` and `.env.example`:

| Variable | Purpose |
| :--- | :--- |
| `PAPERLESS_PORT` | Host port (default `8000`) |
| `PAPERLESS_ADMIN_USER` | Initial admin username |
| `PAPERLESS_ADMIN_PASSWORD` | Initial admin password |
| `PAPERLESS_DB_PASSWORD` | Postgres password (also `PAPERLESS_DBPASS`) |
| `PAPERLESS_SECRET_KEY` | Django secret (generate with openssl) |

Compose wiring (non-secret):

- `PAPERLESS_URL=http://paperless.lan`
- `PAPERLESS_REDIS=redis://paperless-redis:6379`
- `PAPERLESS_DBENGINE=postgresql`
- `PAPERLESS_DBHOST=paperless-db`
- `PAPERLESS_DBNAME=paperless`
- `PAPERLESS_DBUSER=paperless`
- `PAPERLESS_TIKA_ENABLED=1`
- `PAPERLESS_TIKA_ENDPOINT=http://paperless-tika:9998`
- `PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://paperless-gotenberg:3000`
- `TZ=${TZ}`

### Traefik / WUD

- Traefik: `Host(\`paperless.lan\`)`, entrypoint `web`, loadbalancer port `8000`
- WUD: `wud.watch=true` on `paperless` (optional on helpers; prefer watching the app image primarily)

### Init directories

Extend `docker-compose.init.yml`:

- Mount host `/mnt/media-storage/paperless` (or `${DATA_ROOT}/../paperless` equivalent) in addition to existing `/config` mounts
- Create `/config/paperless/{data,pgdata,redis}` and `/paperless/{media,consume,export}` (container paths) with `PUID`/`PGID` ownership
- Do not place Paperless documents under `/media/movies` or `/media/tv`

### Backups

Extend `/home/river/backups/scripts/backup-config.sh`:

1. Keep existing `${CONFIG_ROOT}` → `/home/river/backups/config/` sync (covers `config/paperless/*`)
2. Add: rsync `/mnt/media-storage/paperless/` → `/home/river/backups/paperless/`
3. Mirror `/home/river/backups/paperless/` → `/mnt/media-storage/backups/paperless/`
4. Update `/home/river/backups/RECOVERY.md` to document Paperless document restore

No new cron entry.

### Homarr

After Paperless is healthy and reachable:

- Add an application/tile on the main Homarr board linking to `http://paperless.lan`
- Prefer Homarr UI or HTTP API against running Homarr; do **not** invent a checked-in board JSON file
- If API auth/board IDs make automation unreliable, document a one-line manual UI step as the fallback and still complete compose/backup/README work

### Docs (repo)

Update `README.md`:

- Overview bullet for Paperless-ngx
- Domain table: `paperless.lan`
- Direct port table: `PAPERLESS_PORT` / 8000
- Directory tree for config + `/mnt/media-storage/paperless/`
- Short service detail blurb

### Verification

1. All five containers running; `paperless` healthy / listening on 8000
2. `http://paperless.lan` (and localhost port) serves login; admin login works
3. Drop a PDF into `consume/`; it appears in the library after processing
4. Nightly backup script dry-run or one manual run copies `paperless/` to `/home/river/backups/paperless/`
5. Homarr shows a Paperless tile (or documented manual add if API blocked)

## Risks

- Postgres 18 volume layout differs from older Postgres images — use the upstream path (`/var/lib/postgresql`) and do not mix with a pre-18 data dir
- First-boot admin env vars only apply when no user exists; changing `.env` later will not reset the password
- Document library can grow large; NVMe backup of `media/` must be monitored for disk space
- Homarr V2 API for adding apps may require session/API key discovery — fallback is manual UI
