# Homarr V2 Public Beta Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Switch the existing Homarr service to the V2 public beta image while keeping the current appdata bind mount, Traefik wiring, and docker integration.

**Architecture:** In-place compose change: backup `${CONFIG_ROOT}/homarr`, point `homarr` at `ghcr.io/homarr-labs/homarr-test:v2`, add beta `WORKSHOP_API_URL`, recreate only the Homarr service, then verify health and migration logs.

**Tech Stack:** Docker Compose, Homarr V2 beta (`homarr-test:v2`), Traefik, host bind mount under `/mnt/media-storage/config`

## Global Constraints

- Image must be exactly `ghcr.io/homarr-labs/homarr-test:v2` (not `homarr:latest`, not a named volume swap)
- Keep `${CONFIG_ROOT}/homarr:/appdata` — do not introduce `homarr-v2` named volume
- Keep `SECRET_ENCRYPTION_KEY=${HOMARR_SECRET_ENCRYPTION_KEY}` unchanged
- Keep `ENABLE_DOCKER=true`, docker.sock, Traefik labels, healthcheck, port mapping, `riverdale_network`
- Add `WORKSHOP_API_URL=https://v2.preview.homarr.dev/` for beta only
- Backup appdata before recreate; do not destroy the v1 tree without a dated copy
- Scope is Homarr only — do not recreate the full stack unless required to fix Homarr

## File map

| File | Responsibility |
| :--- | :--- |
| `docker-compose.yml` | Homarr service image + `WORKSHOP_API_URL` |
| `.env.example` | Optional commented Workshop URL for discoverability |
| `README.md` | Note that Homarr is on V2 public beta |
| `${CONFIG_ROOT}/homarr-v1-backup-<date>/` | Host-side rollback snapshot (not in git) |

---

### Task 1: Backup existing Homarr appdata

**Files:**
- Create (host, outside repo): `/mnt/media-storage/config/homarr-v1-backup-2026-09-08/` (use today's date if different)
- Read: `/mnt/media-storage/config/homarr/` (source)

**Interfaces:**
- Consumes: live Homarr appdata at `${CONFIG_ROOT}/homarr`
- Produces: dated backup directory usable for rollback in Task 4 if needed

- [ ] **Step 1: Confirm CONFIG_ROOT and live appdata**

Run from repo root:

```bash
set -a && source .env && set +a
echo "CONFIG_ROOT=$CONFIG_ROOT"
ls -la "$CONFIG_ROOT/homarr"
ls -la "$CONFIG_ROOT/homarr/db"
```

Expected: `CONFIG_ROOT=/mnt/media-storage/config`, and `db/`, `redis/`, `trusted-certificates/` present under `homarr/`.

- [ ] **Step 2: Stop Homarr so SQLite is quiet during copy**

```bash
docker compose stop homarr
```

Expected: `Container homarr Stopped` (or equivalent).

- [ ] **Step 3: Copy appdata to a dated backup**

`db/` is owned by root inside the container mount — use `sudo` if needed:

```bash
BACKUP_DIR="$CONFIG_ROOT/homarr-v1-backup-$(date +%Y-%m-%d)"
sudo cp -a "$CONFIG_ROOT/homarr" "$BACKUP_DIR"
sudo chown -R "$(id -u):$(id -g)" "$BACKUP_DIR" 2>/dev/null || true
du -sh "$CONFIG_ROOT/homarr" "$BACKUP_DIR"
ls -la "$BACKUP_DIR"
```

Expected: backup directory exists with `db/`, `redis/`, `trusted-certificates/`; sizes roughly match.

- [ ] **Step 4: Commit is N/A for host data**

Do not commit anything under `/mnt/media-storage`. Record the backup path in the session notes / PR description only.

---

### Task 2: Update compose, env example, and README

**Files:**
- Modify: `docker-compose.yml` (homarr service ~lines 412–439)
- Modify: `.env.example` (Homarr section ~lines 44–45)
- Modify: `README.md` (Homarr bullet ~line 86)

**Interfaces:**
- Consumes: backup from Task 1 already on disk
- Produces: compose definition that pulls/runs `homarr-test:v2` with Workshop URL

- [ ] **Step 1: Change Homarr image and add Workshop env**

In `docker-compose.yml`, update the `homarr` service so the image and environment look exactly like this (preserve volumes, ports, healthcheck, labels, networks):

```yaml
  # Homarr - Unified dashboard for all services (V2 public beta)
  homarr:
    image: ghcr.io/homarr-labs/homarr-test:v2
    container_name: homarr
    environment:
      - TZ=${TZ}
      - SECRET_ENCRYPTION_KEY=${HOMARR_SECRET_ENCRYPTION_KEY}
      - ENABLE_DOCKER=true
      - WORKSHOP_API_URL=https://v2.preview.homarr.dev/
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${CONFIG_ROOT}/homarr:/appdata
    ports:
      - "${HOMARR_PORT:-7575}:7575"
    restart: unless-stopped
    networks:
      - riverdale_network
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://127.0.0.1:7575 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.homarr.rule=Host(`homarr.lan`)"
      - "traefik.http.routers.homarr.entrypoints=web"
      - "traefik.http.services.homarr.loadbalancer.server.port=7575"
      - "wud.watch=true"
```

- [ ] **Step 2: Document Workshop URL in `.env.example`**

Replace the Homarr secret block with:

```bash
# Homarr Dashboard (generate with: openssl rand -hex 32)
HOMARR_SECRET_ENCRYPTION_KEY=your_64_char_hex_secret_key
# Homarr V2 public beta only (remove after GA):
# WORKSHOP_API_URL is set in docker-compose.yml for the beta image
```

- [ ] **Step 3: Note V2 beta in README service details**

Change the Homarr bullet under Main Media Server Stack from:

```markdown
- **Homarr** (7575): Unified dashboard for all services
```

to:

```markdown
- **Homarr** (7575): Unified dashboard for all services (V2 public beta image `homarr-test:v2`; Workshop via `WORKSHOP_API_URL`)
```

- [ ] **Step 4: Validate compose syntax**

```bash
docker compose config --quiet
```

Expected: exit code `0`, no output (or only warnings unrelated to Homarr).

- [ ] **Step 5: Commit**

```bash
git add docker-compose.yml .env.example README.md
git commit -m "$(cat <<'EOF'
chore: switch Homarr to V2 public beta image

EOF
)"
```

---

### Task 3: Recreate Homarr and verify migration

**Files:**
- No repo files (runtime only)
- Uses: updated `docker-compose.yml` from Task 2
- Uses: live appdata at `/mnt/media-storage/config/homarr`

**Interfaces:**
- Consumes: V2 beta compose config
- Produces: running healthy `homarr` container on migrated SQLite

- [ ] **Step 1: Pull the V2 beta image**

```bash
docker compose pull homarr
```

Expected: pulls `ghcr.io/homarr-labs/homarr-test:v2` successfully.

- [ ] **Step 2: Recreate only Homarr**

```bash
docker compose up -d --force-recreate --no-deps homarr
```

Expected: container created and started.

- [ ] **Step 3: Confirm image and migration logs**

```bash
docker inspect homarr --format '{{.Config.Image}}'
docker logs homarr 2>&1 | grep -E 'migration|Migrat|ERROR|aborting' | head -40
docker compose ps homarr
```

Expected:
- Image is `ghcr.io/homarr-labs/homarr-test:v2`
- Logs show migrations ran without `ERROR: DB migrations failed, aborting startup`
- Container state is `running` / healthy (health may take ~30s due to `start_period`)

- [ ] **Step 4: HTTP smoke checks**

```bash
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7575/
curl -sS -o /dev/null -w '%{http_code}\n' -H 'Host: homarr.lan' http://127.0.0.1/
```

Expected: HTTP `200` or `302`/`307` (auth redirect is OK). Not `000` / connection refused / `502`.

- [ ] **Step 5: Manual UI checks (human or browser)**

Open `http://homarr.lan` (or `http://localhost:7575`):

1. Existing board loads (not empty first-run wizard only — unless the install was never configured)
2. Docker-related widgets / container list still function (sock + `ENABLE_DOCKER`)

If any of Steps 3–5 fail, execute Task 4 rollback immediately.

- [ ] **Step 6: Commit is N/A**

No further git commit unless verification forced a compose tweak; if so, commit that fix with a clear message before finishing.

---

### Task 4: Rollback procedure (only if verification fails)

**Files:**
- Modify: `docker-compose.yml` (revert Homarr image/env)
- Restore: `/mnt/media-storage/config/homarr` from backup

**Interfaces:**
- Consumes: backup path from Task 1
- Produces: Homarr back on `ghcr.io/homarr-labs/homarr:latest` with v1 appdata

- [ ] **Step 1: Stop Homarr**

```bash
docker compose stop homarr
```

- [ ] **Step 2: Restore appdata from backup**

```bash
set -a && source .env && set +a
BACKUP_DIR="$CONFIG_ROOT/homarr-v1-backup-2026-09-08"  # adjust date if needed
sudo rm -rf "$CONFIG_ROOT/homarr"
sudo cp -a "$BACKUP_DIR" "$CONFIG_ROOT/homarr"
```

- [ ] **Step 3: Revert compose image and remove Workshop URL**

Restore the `homarr` service header to:

```yaml
  # Homarr - Unified dashboard for all services
  homarr:
    image: ghcr.io/homarr-labs/homarr:latest
    container_name: homarr
    environment:
      - TZ=${TZ}
      - SECRET_ENCRYPTION_KEY=${HOMARR_SECRET_ENCRYPTION_KEY}
      - ENABLE_DOCKER=true
```

Also revert the README Homarr bullet and `.env.example` Homarr comment block to their pre-Task-2 text.

- [ ] **Step 4: Recreate and verify stable image**

```bash
docker compose up -d --force-recreate --no-deps homarr
docker inspect homarr --format '{{.Config.Image}}'
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7575/
```

Expected: image `ghcr.io/homarr-labs/homarr:latest`, HTTP `200`/`302`/`307`.

- [ ] **Step 5: Commit rollback**

```bash
git add docker-compose.yml .env.example README.md
git commit -m "$(cat <<'EOF'
revert: roll Homarr back to stable v1 image

EOF
)"
```

---

## Spec coverage checklist

| Spec requirement | Task |
| :--- | :--- |
| Image → `homarr-test:v2` | Task 2 |
| Add `WORKSHOP_API_URL` | Task 2 |
| Keep bind mount / Traefik / docker.sock / secret | Task 2 (unchanged fields) |
| Backup before recreate | Task 1 |
| Recreate + migration verification | Task 3 |
| README + `.env.example` notes | Task 2 |
| Rollback path | Task 4 |
