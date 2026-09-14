# Paperless-ngx Full Stack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Paperless-ngx (web + Postgres + Valkey + Gotenberg + Tika) to the Riverdale compose stack at `paperless.lan`, with document storage on the media disk and nightly NVMe backups via the existing backup script, plus a Homarr tile.

**Architecture:** Five new services inline in `docker-compose.yml` on `riverdale_network`. Bind-mount DB/state under `${CONFIG_ROOT}/paperless/` and documents under `${PAPERLESS_ROOT}` (`/mnt/media-storage/paperless`). Extend `backup-config.sh` to rsync the document tree to `/home/river/backups/paperless/`. Homarr tile added after the UI is healthy.

**Tech Stack:** Docker Compose, Paperless-ngx, PostgreSQL 18, Valkey 9, Gotenberg 8, Apache Tika, Traefik, existing rsync backup cron, Homarr V2

## Global Constraints

- Full stack only: `paperless`, `paperless-db`, `paperless-redis`, `paperless-gotenberg`, `paperless-tika` (no SQLite-only shortcut)
- Bind mounts only — no Docker named volumes for Paperless data
- Documents under `/mnt/media-storage/paperless/{media,consume,export}` — never under `media/movies` or `media/tv`
- Config/DB under `${CONFIG_ROOT}/paperless/{data,pgdata,redis}`
- Traefik host: `paperless.lan`, entrypoint `web`, backend port `8000`
- Extend existing `/home/river/backups/scripts/backup-config.sh` — no new cron job
- Homarr: add tile for `http://paperless.lan`; no checked-in board JSON
- LAN only — no external HTTPS / public exposure in this work
- Follow existing compose patterns (PUID/PGID/TZ, `restart: unless-stopped`, `riverdale_network`, WUD on the main app image)

## File map

| File | Responsibility |
| :--- | :--- |
| `docker-compose.yml` | Five Paperless services + Traefik/WUD labels |
| `docker-compose.init.yml` | Create paperless config + document directories |
| `.env` / `.env.example` | Ports, admin, DB password, secret key, `PAPERLESS_ROOT` |
| `README.md` | Service list, domain/port tables, directory tree |
| `/home/river/backups/scripts/backup-config.sh` | Rsync document library to NVMe (+ mirror) |
| `/home/river/backups/RECOVERY.md` | Document Paperless restore path |

Spec: `docs/superpowers/specs/2026-09-13-paperless-ngx-design.md`

---

### Task 1: Env vars, secrets, and host directories

**Files:**
- Modify: `.env.example`
- Modify: `.env` (host secrets; gitignored)
- Modify: `docker-compose.init.yml`
- Create (host): `/mnt/media-storage/config/paperless/{data,pgdata,redis}`
- Create (host): `/mnt/media-storage/paperless/{media,consume,export}`

**Interfaces:**
- Consumes: existing `PUID`, `PGID`, `TZ`, `CONFIG_ROOT`, `DATA_ROOT` from `.env`
- Produces: `PAPERLESS_PORT`, `PAPERLESS_ROOT`, `PAPERLESS_ADMIN_USER`, `PAPERLESS_ADMIN_PASSWORD`, `PAPERLESS_DB_PASSWORD`, `PAPERLESS_SECRET_KEY` available to compose; empty host dirs ready for mounts

- [ ] **Step 1: Generate secrets**

```bash
cd /home/river/riverdale_server
openssl rand -base64 32 | tr -d '/+=' | head -c 32; echo   # admin/db password candidate
openssl rand -hex 32   # PAPERLESS_SECRET_KEY
```

Expected: two random strings printed. Keep them for Step 3.

- [ ] **Step 2: Update `.env.example`**

Add after the Bazarr port line (near other `*_PORT` vars):

```bash
PAPERLESS_PORT=8000
```

Add after storage paths (`MEDIA_ROOT=...`):

```bash
# Paperless document library (not under media/movies|tv)
PAPERLESS_ROOT=/mnt/media-storage/paperless
```

Add a new section after WUD auth (or near other app secrets):

```bash
# Paperless-ngx (initial admin created on first boot only)
PAPERLESS_ADMIN_USER=admin
PAPERLESS_ADMIN_PASSWORD=set_a_strong_password
PAPERLESS_DB_PASSWORD=set_a_strong_password
PAPERLESS_SECRET_KEY=generate_with_openssl_rand_hex_32
```

- [ ] **Step 3: Update live `.env`**

Add the same keys with real values (use generated secrets; `PAPERLESS_ADMIN_USER=admin` is fine). Do not commit `.env`.

- [ ] **Step 4: Extend `docker-compose.init.yml`**

Add volume mount for paperless docs and mkdir lines. The init service volumes should become:

```yaml
    volumes:
      - ${MEDIA_ROOT}:/media
      - ${DOWNLOADS_ROOT}:/downloads
      - ${CONFIG_ROOT}:/config
      - ${PAPERLESS_ROOT}:/paperless
```

In the `mkdir -p` command block, add:

```sh
        mkdir -p /config/paperless/data /config/paperless/pgdata /config/paperless/redis
        mkdir -p /paperless/media /paperless/consume /paperless/export
```

Keep existing `chown -R` over `/media /downloads /config`; also chown paperless:

```sh
        chown -R \$${PUID}:\$${PGID} /paperless 2>/dev/null || true
        chmod -R 755 /paperless 2>/dev/null || true
```

- [ ] **Step 5: Run init and verify directories**

```bash
cd /home/river/riverdale_server
set -a && source .env && set +a
docker compose -f docker-compose.init.yml up
ls -la "$CONFIG_ROOT/paperless"
ls -la "$PAPERLESS_ROOT"
```

Expected: `data`, `pgdata`, `redis` under config; `media`, `consume`, `export` under paperless root.

- [ ] **Step 6: Commit**

```bash
git add .env.example docker-compose.init.yml
git commit -m "$(cat <<'EOF'
feat: add Paperless env template and init directories

EOF
)"
```

Do not `git add .env`.

---

### Task 2: Add Paperless services to compose

**Files:**
- Modify: `docker-compose.yml` (insert before the `whoami` service)

**Interfaces:**
- Consumes: env vars from Task 1; `riverdale_network`; Traefik already on the network
- Produces: five compose services named `paperless`, `paperless-db`, `paperless-redis`, `paperless-gotenberg`, `paperless-tika`

- [ ] **Step 1: Validate compose still parses before edit**

```bash
cd /home/river/riverdale_server
docker compose config -q
```

Expected: exit 0, no output.

- [ ] **Step 2: Insert the five services before `whoami`**

Paste this block immediately above the `# whoami` service comment:

```yaml
  # Paperless-ngx - Document management (OCR / archive)
  paperless-redis:
    image: docker.io/valkey/valkey:9-alpine
    container_name: paperless-redis
    restart: unless-stopped
    networks:
      - riverdale_network
    volumes:
      - ${CONFIG_ROOT}/paperless/redis:/data

  paperless-db:
    image: docker.io/library/postgres:18
    container_name: paperless-db
    restart: unless-stopped
    networks:
      - riverdale_network
    volumes:
      - ${CONFIG_ROOT}/paperless/pgdata:/var/lib/postgresql
    environment:
      - POSTGRES_DB=paperless
      - POSTGRES_USER=paperless
      - POSTGRES_PASSWORD=${PAPERLESS_DB_PASSWORD}

  paperless-gotenberg:
    image: docker.io/gotenberg/gotenberg:8
    container_name: paperless-gotenberg
    restart: unless-stopped
    networks:
      - riverdale_network
    command:
      - "gotenberg"
      - "--chromium-disable-javascript=true"
      - "--chromium-allow-list=file:///tmp/.*"
      - "--api-timeout=60s"

  paperless-tika:
    image: docker.io/apache/tika:latest
    container_name: paperless-tika
    restart: unless-stopped
    networks:
      - riverdale_network

  paperless:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    container_name: paperless
    restart: unless-stopped
    depends_on:
      - paperless-db
      - paperless-redis
      - paperless-gotenberg
      - paperless-tika
    networks:
      - riverdale_network
    ports:
      - "${PAPERLESS_PORT:-8000}:8000"
    volumes:
      - ${CONFIG_ROOT}/paperless/data:/usr/src/paperless/data
      - ${PAPERLESS_ROOT}/media:/usr/src/paperless/media
      - ${PAPERLESS_ROOT}/consume:/usr/src/paperless/consume
      - ${PAPERLESS_ROOT}/export:/usr/src/paperless/export
    environment:
      - TZ=${TZ}
      - USERMAP_UID=${PUID}
      - USERMAP_GID=${PGID}
      - PAPERLESS_REDIS=redis://paperless-redis:6379
      - PAPERLESS_DBENGINE=postgresql
      - PAPERLESS_DBHOST=paperless-db
      - PAPERLESS_DBNAME=paperless
      - PAPERLESS_DBUSER=paperless
      - PAPERLESS_DBPASS=${PAPERLESS_DB_PASSWORD}
      - PAPERLESS_SECRET_KEY=${PAPERLESS_SECRET_KEY}
      - PAPERLESS_URL=http://paperless.lan
      - PAPERLESS_ADMIN_USER=${PAPERLESS_ADMIN_USER}
      - PAPERLESS_ADMIN_PASSWORD=${PAPERLESS_ADMIN_PASSWORD}
      - PAPERLESS_TIKA_ENABLED=1
      - PAPERLESS_TIKA_ENDPOINT=http://paperless-tika:9998
      - PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://paperless-gotenberg:3000
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://127.0.0.1:8000/ || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.paperless.rule=Host(`paperless.lan`)"
      - "traefik.http.routers.paperless.entrypoints=web"
      - "traefik.http.services.paperless.loadbalancer.server.port=8000"
      - "wud.watch=true"
```

- [ ] **Step 3: Validate compose config**

```bash
docker compose config -q
docker compose config | grep -E 'paperless|PAPERLESS_' | head -40
```

Expected: exit 0; services resolve; secrets appear substituted (do not paste secrets into logs/chat unnecessarily).

- [ ] **Step 4: Commit**

```bash
git add docker-compose.yml
git commit -m "$(cat <<'EOF'
feat: add Paperless-ngx full stack to compose

EOF
)"
```

---

### Task 3: Start Paperless and verify login

**Files:**
- None in git (runtime only)

**Interfaces:**
- Consumes: Task 2 compose services + Task 1 dirs/secrets
- Produces: healthy `paperless` container serving login at `paperless.lan` and localhost port

- [ ] **Step 1: Pull and start only Paperless-related services**

```bash
cd /home/river/riverdale_server
docker compose pull paperless paperless-db paperless-redis paperless-gotenberg paperless-tika
docker compose up -d paperless-db paperless-redis paperless-gotenberg paperless-tika paperless
```

Expected: five containers created/started without immediate exit.

- [ ] **Step 2: Wait for health and check logs**

```bash
sleep 20
docker compose ps paperless paperless-db paperless-redis paperless-gotenberg paperless-tika
docker logs paperless --tail 80 2>&1
```

Expected: `paperless` eventually healthy or at least Up; logs show migrations / “Listening” / no repeated crash loop. If Postgres path errors appear, stop and confirm pgdata mount is `/var/lib/postgresql` (Postgres 18), not `/var/lib/postgresql/data`.

- [ ] **Step 3: HTTP checks**

```bash
set -a && source .env && set +a
curl -sS -o /dev/null -w 'direct:%{http_code}\n' "http://127.0.0.1:${PAPERLESS_PORT:-8000}/"
curl -sS -o /dev/null -w 'traefik:%{http_code}\n' -H 'Host: paperless.lan' http://127.0.0.1/
```

Expected: HTTP `200`, `302`, or `301` (login redirect is OK). Not `000` / connection refused / Traefik 404.

- [ ] **Step 4: Confirm admin login works**

Open `http://paperless.lan` (or `http://localhost:$PAPERLESS_PORT`) and sign in with `PAPERLESS_ADMIN_USER` / `PAPERLESS_ADMIN_PASSWORD` from `.env`.

Expected: dashboard loads after login.

- [ ] **Step 5: Commit is N/A**

No code change in this task unless a compose fix was required — if you fixed compose, commit that fix before continuing.

---

### Task 4: Extend nightly backup for document library

**Files:**
- Modify: `/home/river/backups/scripts/backup-config.sh`
- Modify: `/home/river/backups/RECOVERY.md`

**Interfaces:**
- Consumes: live `/mnt/media-storage/paperless/` and existing backup layout under `/home/river/backups/`
- Produces: NVMe copy at `/home/river/backups/paperless/` and mirror at `/mnt/media-storage/backups/paperless/`

- [ ] **Step 1: Add paperless rsync to `backup-config.sh`**

After the compose rsync block (before the `sudo mkdir -p /mnt/media-storage/backups/...` section), insert:

```bash
if [ -d /mnt/media-storage/paperless ]; then
  mkdir -p /home/river/backups/paperless
  sudo rsync -a --delete \
    /mnt/media-storage/paperless/ /home/river/backups/paperless/ >> "$LOG" 2>&1
  sudo chown -R river:river /home/river/backups/paperless
fi
```

Extend the media-disk mirror section to:

```bash
sudo mkdir -p /mnt/media-storage/backups/config /mnt/media-storage/backups/compose /mnt/media-storage/backups/paperless
sudo rsync -a --delete /home/river/backups/config/  /mnt/media-storage/backups/config/  >> "$LOG" 2>&1
sudo rsync -a --delete /home/river/backups/compose/ /mnt/media-storage/backups/compose/ >> "$LOG" 2>&1
if [ -d /home/river/backups/paperless ]; then
  sudo rsync -a --delete /home/river/backups/paperless/ /mnt/media-storage/backups/paperless/ >> "$LOG" 2>&1
fi
sudo cp /home/river/backups/RECOVERY.md /mnt/media-storage/backups/RECOVERY.md
sudo chown -R river:river /mnt/media-storage/backups/config /mnt/media-storage/backups/compose /mnt/media-storage/backups/paperless /mnt/media-storage/backups/RECOVERY.md
```

Keep the existing mountpoint guard and config rsync unchanged (they already cover `${CONFIG_ROOT}/paperless`).

- [ ] **Step 2: Update `RECOVERY.md`**

In “What’s backed up here”, add a third folder bullet:

```markdown
- `paperless/` — Paperless document library (`media/`, `consume/`, `export/`).
  App DB/state for Paperless also lives under `config/paperless/` (Postgres,
  Valkey, Paperless `data/`).
```

In recovery steps (after restoring config), add:

```markdown
### Restore Paperless documents
If the media disk was rebuilt but NVMe backups survived:
```bash
sudo mkdir -p /mnt/media-storage/paperless
sudo rsync -a /home/river/backups/paperless/ /mnt/media-storage/paperless/
sudo chown -R 1000:1000 /mnt/media-storage/paperless   # match PUID/PGID
```
Also ensure `/mnt/media-storage/config/paperless/` was restored with the rest of `config/`.
```

- [ ] **Step 3: Run backup once manually**

```bash
/home/river/backups/scripts/backup-config.sh
tail -30 /home/river/backups/backup.log
ls -la /home/river/backups/paperless
du -sh /home/river/backups/paperless /mnt/media-storage/backups/paperless 2>/dev/null
```

Expected: log shows “backup complete”; `paperless` dirs exist on NVMe (may be nearly empty initially).

- [ ] **Step 4: Commit note**

These files live outside the git repo (`~/backups/`). Do not commit them into `riverdale_server`. Optionally mention the backup extension in the README task commit message / PR description.

---

### Task 5: README documentation

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: final service names, `paperless.lan`, `PAPERLESS_PORT`, directory layout from Tasks 1–2
- Produces: README that lists Paperless like other first-class services

- [ ] **Step 1: Overview bullet**

Under the overview capabilities list, add:

```markdown
- **Document management** with Paperless-ngx (OCR, tags, full-text search)
```

- [ ] **Step 2: Domain + port tables**

In Main Services table add:

```markdown
| **Paperless** | `paperless.lan` | Document management (OCR/archive) |
```

In Direct Port Access table add:

```markdown
| **Paperless** | `http://localhost:8000` | 8000 | Document management |
```

- [ ] **Step 3: Service details + directory tree**

In Service Details, add:

```markdown
- **Paperless-ngx** (8000): Document management with OCR (Postgres + Valkey + Gotenberg + Tika)
```

In the config directory tree under `/mnt/media-storage/config/`, add `paperless/`.

Add a sibling tree entry for documents:

```text
├── /mnt/media-storage/paperless/  # Paperless document library
│   ├── media/
│   ├── consume/                   # Drop PDFs here for ingest
│   └── export/
```

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs: document Paperless-ngx service and paths

EOF
)"
```

---

### Task 6: Homarr app tile

**Files:**
- None required in git (Homarr SQLite appdata under `${CONFIG_ROOT}/homarr`)

**Interfaces:**
- Consumes: healthy `http://paperless.lan` from Task 3; running Homarr V2
- Produces: Paperless app visible on the Homarr board

- [ ] **Step 1: Confirm Homarr and Paperless are up**

```bash
docker compose ps homarr paperless
curl -sS -o /dev/null -w '%{http_code}\n' -H 'Host: paperless.lan' http://127.0.0.1/
curl -sS -o /dev/null -w '%{http_code}\n' -H 'Host: homarr.lan' http://127.0.0.1/
```

Expected: both reachable (2xx/3xx).

- [ ] **Step 2: Add tile via Homarr UI (primary path)**

1. Open `http://homarr.lan`
2. Edit the main board
3. Add an App / Link item:
   - Name: `Paperless`
   - URL: `http://paperless.lan`
   - Icon: Paperless / documents icon if available (optional)
4. Save the board

Expected: clicking the tile opens Paperless login/dashboard.

- [ ] **Step 3: API automation (optional, only if UI is awkward)**

If you prefer automation and Homarr exposes a usable API session for this install, create the app via API. If auth/board IDs are unclear after ~10 minutes, **stop and keep the UI result from Step 2** — do not invent a checked-in JSON board file.

- [ ] **Step 4: Commit is N/A**

Homarr board state is in `${CONFIG_ROOT}/homarr` and is already covered by the nightly config backup.

---

### Task 7: Consume-folder smoke test

**Files:**
- None (runtime verification)

**Interfaces:**
- Consumes: running Paperless + `${PAPERLESS_ROOT}/consume`
- Produces: at least one document visible in the Paperless library

- [ ] **Step 1: Drop a small PDF into consume**

```bash
set -a && source /home/river/riverdale_server/.env && set +a
# Minimal valid-enough PDF
printf '%%PDF-1.1\n1 0 obj<<>>endobj\ntrailer<<>>\n%%%%EOF\n' > "$PAPERLESS_ROOT/consume/riverdale-smoke-test.pdf"
ls -la "$PAPERLESS_ROOT/consume"
```

Expected: file appears in consume (Paperless may remove it quickly after ingest).

- [ ] **Step 2: Watch processing**

```bash
docker logs paperless --since 2m 2>&1 | grep -iE 'consume|added|success|error|failed' | tail -40
sleep 15
ls -la "$PAPERLESS_ROOT/consume"
ls -la "$PAPERLESS_ROOT/media/documents/originals" 2>/dev/null | tail -10
```

Expected: consume file gone or processing logged; originals path gains a file **or** UI Documents list shows the smoke test. If Tika/Gotenberg warnings appear but the PDF still lands, that is acceptable for this smoke test.

- [ ] **Step 3: Confirm in UI**

Open Paperless → Documents and find `riverdale-smoke-test` (title may be derived from filename).

Expected: one document present.

- [ ] **Step 4: Final status check**

```bash
docker compose ps paperless paperless-db paperless-redis paperless-gotenberg paperless-tika
curl -sS -o /dev/null -w 'paperless:%{http_code}\n' -H 'Host: paperless.lan' http://127.0.0.1/
```

Expected: all Up; Traefik returns success/redirect.

- [ ] **Step 5: Commit is N/A** unless a bugfix was required during testing.

---

## Self-review (plan vs spec)

| Spec requirement | Task |
| :--- | :--- |
| Five-container full stack inline in compose | Task 2 |
| Bind mounts config vs documents paths | Tasks 1–2 |
| Traefik `paperless.lan` + port env | Tasks 1–2 |
| Init directories | Task 1 |
| Env secrets in `.env` / `.env.example` | Task 1 |
| Extend existing backup + RECOVERY.md | Task 4 |
| README updates | Task 5 |
| Homarr tile | Task 6 |
| Verification / consume smoke | Tasks 3, 7 |
| Non-goals (no public HTTPS, no AI addons, no named volumes) | Honored — not scheduled |

No TBD/placeholder steps remain. Service/env names are consistent across tasks (`paperless-db`, `PAPERLESS_DB_PASSWORD` → `PAPERLESS_DBPASS`, `PAPERLESS_ROOT`).
