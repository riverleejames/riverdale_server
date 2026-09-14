# Homarr V2 Public Beta (In-Place)

**Date:** 2026-09-08  
**Status:** Approved for implementation planning  
**Stack:** riverdale_server (Docker Compose)

## Goal

Move the existing Homarr service from stable `ghcr.io/homarr-labs/homarr:latest` (v1.x) to the Homarr **V2 public beta** image `ghcr.io/homarr-labs/homarr-test:v2`, reusing the current `/appdata` bind mount so boards and integrations survive via on-startup SQLite migrations.

## Non-goals

- Waiting for Homarr 2.0 GA / `v2.0.0` on the stable image
- Switching to a Docker named volume (`homarr-v2`) as in the upstream beta snippet
- Running a parallel second Homarr container for side-by-side testing
- Rebuilding boards or integrations from scratch
- Removing Traefik, docker.sock, or other stack wiring already present

## Context

- Service today: `homarr` in `docker-compose.yml`
- Image: `ghcr.io/homarr-labs/homarr:latest` (effectively v1.77.0 as of 2026-09-06)
- Data: `${CONFIG_ROOT}/homarr:/appdata` (SQLite at `/appdata/db/db.sqlite`)
- Already configured: `SECRET_ENCRYPTION_KEY`, `ENABLE_DOCKER=true`, docker.sock, Traefik (`homarr.lan`), healthcheck, port `7575`
- Upstream beta sample uses `homarr-test:v2`, optional `WORKSHOP_API_URL=https://v2.preview.homarr.dev/`, and a fresh named volume; we intentionally keep the existing bind mount instead

## Approach (chosen)

**In-place swap with backup first.**

1. Snapshot `${CONFIG_ROOT}/homarr` to `${CONFIG_ROOT}/homarr-v1-backup-<date>` before recreate
2. Change compose image to `ghcr.io/homarr-labs/homarr-test:v2`
3. Add `WORKSHOP_API_URL=https://v2.preview.homarr.dev/` (beta-only Workshop API)
4. Keep all other mounts, env, labels, healthcheck, and networking
5. Recreate the `homarr` service; rely on container entrypoint DB migrations

### Alternatives considered

| Option | Summary | Why not |
| :--- | :--- | :--- |
| Parallel V2 service | Second container + copied appdata | Extra Traefik/port churn for a beta |
| Named volume / fresh install | Upstream snippet literally | Conflicts with reusing existing appdata |

## Design

### Compose / service

| Item | Action |
| :--- | :--- |
| `image` | `ghcr.io/homarr-labs/homarr-test:v2` |
| `WORKSHOP_API_URL` | Add `https://v2.preview.homarr.dev/` |
| Volume | Keep `${CONFIG_ROOT}/homarr:/appdata` |
| `SECRET_ENCRYPTION_KEY` | Keep (same key; required for encrypted secrets) |
| `ENABLE_DOCKER` + docker.sock | Keep |
| Traefik labels / port / healthcheck / network | Keep unchanged |

### Rollback

1. Stop Homarr
2. Restore `${CONFIG_ROOT}/homarr` from the dated backup
3. Revert image to `ghcr.io/homarr-labs/homarr:latest`
4. Remove `WORKSHOP_API_URL`
5. Recreate the service

### Docs

- README: note Homarr is on the V2 public beta image and that `WORKSHOP_API_URL` is beta-only
- `.env.example`: optional commented `WORKSHOP_API_URL` for discoverability (no new secrets)

### Verification

1. Container is healthy and reachable at `homarr.lan` / `:7575`
2. Existing board loads (data preserved through migration)
3. Docker integration still works
4. Container logs show DB migrations succeeded

## Risks

- Beta image may introduce breaking schema or UI changes; backup is mandatory
- `WORKSHOP_API_URL` points at Homarr’s hosted preview Workshop; remove or revisit at GA
- If migration fails, container may abort on startup — restore from backup and revert image
