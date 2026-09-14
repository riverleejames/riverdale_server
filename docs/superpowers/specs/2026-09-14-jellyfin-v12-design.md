# Jellyfin v12 cutover (Plex retained for rollback)

**Date:** 2026-09-14  
**Status:** Approved for implementation (architecture A; watch-history import; Plex stopped via compose profile)  
**Stack:** riverdale_server (Docker Compose)

## Goal

Make **Jellyfin 12** the live media server for Riverdale: same movie/TV files, Intel QuickSync, Seerr, Maintainerr, and Homarr. Keep **Plex installed and restorable** (compose service + config untouched) until we choose to delete it.

## Non-goals

- Deleting the Plex container definition, config, or libraries
- Copying or rewriting media files
- Public HTTPS / remote Jellyfin (LAN `.lan` only, same as other apps)
- Experimental Seerr `preview-media-server-migration` image unless `:latest` already exposes switch UI
- Music/photos/home-videos libraries (movies + TV only, matching Plex)
- Two-way WatchState cron after the trial (one-way Plex → Jellyfin; optional reverse export only if we revert)
- New Pi-hole/DNS automation if records are managed on the router

## Context

- Plex: `lscr.io/linuxserver/plex:latest`, `network_mode: host`, `/dev/dri`, `${DATA_ROOT}/media:/data/media:ro`, config `${CONFIG_ROOT}/plex`
- Seerr `main.mediaServerType` is currently `1` (Plex) at `192.168.1.37:32400`; Jellyfin settings block exists but is empty
- Maintainerr rules are Plex-watch-based; v3 can switch to Jellyfin with rule migration
- Traefik `.lan` hosts for everything except Plex
- Nightly backup already rsyncs `${CONFIG_ROOT}` → `/home/river/backups/config/` (excludes Plex cache/metadata artwork)

## Approach (chosen)

**A — Single compose file, LinuxServer Jellyfin, Traefik `jellyfin.lan`.**

1. Git branch `feat/jellyfin-v12`
2. Dated snapshot of app configs **before** Seerr/Maintainerr/Homarr change
3. Add `jellyfin` + `watchstate` to `docker-compose.yml`
4. Put Plex on compose profile `plex` so default `docker compose up -d` does not start it
5. One-way WatchState import (Plex → Jellyfin) while Plex is still running, then stop Plex
6. Point Seerr and Maintainerr at Jellyfin in place
7. Homarr tile for `http://jellyfin.lan`

### Alternatives considered

| Option | Summary | Why not |
| :--- | :--- | :--- |
| B — official `jellyfin/jellyfin:12` + host net | TV auto-discovery like Plex | Breaks Traefik/PUID/WUD patterns |
| C — overlay `docker-compose.jellyfin.yml` | Isolated file | Seerr/Maintainerr still mutate on disk; extra compose friction |

## Architecture

- Same `riverdale_network` as Sonarr/Radarr/Seerr
- Shared read-only media tree; no second copy
- Shared `/dev/dri` (Plex stopped during the trial so it does not contend for QSV)
- Rollback = git + config snapshot + `docker compose --profile plex up -d plex`

## Services

### `jellyfin`

| Field | Value |
| :--- | :--- |
| Image | `lscr.io/linuxserver/jellyfin:latest` (v12 family) |
| Network | `riverdale_network` (not host) |
| Media | `${DATA_ROOT}/media:/data/media:ro` |
| Config | `${CONFIG_ROOT}/jellyfin:/config` |
| Transcode | `/dev/shm:/transcode` (same as Plex) |
| GPU | `devices: [/dev/dri:/dev/dri]`; LinuxServer maps `abc` onto the device group. Also `group_add: ["992"]` (`render` on this host) so QSV works if the image does not auto-fix `renderD128` |
| Published URL | `JELLYFIN_PublishedServerUrl=http://jellyfin.lan` |
| Ports | `${JELLYFIN_PORT:-8096}:8096` |
| Traefik | `Host(\`jellyfin.lan\`)`, entrypoint `web`, LB `8096` |
| Healthcheck | `curl -f http://localhost:8096/health` |
| WUD | `wud.watch=true` |

Libraries (after wizard):

- Movies → `/data/media/movies`
- TV → `/data/media/tv`

Hardware acceleration: Intel QuickSync (VAAPI/QSV) in Dashboard → Playback, after first login. Enable once libraries exist.

### `plex` (retained, not default)

Add:

```yaml
profiles:
  - plex
```

Do **not** start Plex with a profile-less `docker compose up -d`. Keep it running with `docker compose --profile plex up -d` until WatchState has imported, then omit the profile so Compose stops it.

Do not change Plex volumes, claim token, or libraries.

### `watchstate`

| Field | Value |
| :--- | :--- |
| Image | `ghcr.io/arabcoders/watchstate:latest` |
| User | `${PUID}:${PGID}` |
| Config | `${CONFIG_ROOT}/watchstate:/config` |
| Host port | `${WATCHSTATE_PORT:-8282}:8080` (8080 is Traefik’s dashboard) |
| Traefik | `Host(\`watchstate.lan\`)`, LB `8080` |
| extra_hosts | `host.docker.internal:host-gateway` so it can reach Plex on the host (`http://host.docker.internal:32400`) |
| Jellyfin URL | `http://jellyfin:8096` on `riverdale_network` |

One-way: Import from Plex, Export to Jellyfin. Map Plex users → Jellyfin users via WatchState identities. After the initial force-export, leave WatchState running but do **not** enable two-way cron (Plex will be stopped). Keep the container so a revert can export Jellyfin → Plex after starting Plex again.

### Seerr

In-place switch after Jellyfin libraries exist:

1. Snapshot `${CONFIG_ROOT}/seerr` is already in the pre-cutover backup
2. If Settings → General has **Switch media server**, use it (link users first)
3. Else: stop Seerr, keep `db.sqlite3` / request DB, reset `settings.json` media-server block via the documented owner wizard (re-paste Sonarr/Radarr/Telegram/ntfy from the snapshot — do not lose request history)
4. Jellyfin connection: hostname `jellyfin`, port `8096`, SSL off (docker DNS). Fallback `192.168.1.37:8096` if name resolution fails inside the container

Telegram bot stays pointed at `http://seerr:5055` (unchanged).

### Maintainerr

Use built-in **media server switch** with rule migration (Plex → Jellyfin). Point at `http://jellyfin:8096` with a Jellyfin API key. Sonarr/Radarr/Seerr connections stay. Disk-space emergency rules are *arr-based and should survive.

### Homarr

Add an app tile for `http://jellyfin.lan`. Leave the Plex tile in place but unused (or hide it) so rollback does not require recreating it. Prefer UI/API; do not check in board JSON.

## Storage / init

`docker-compose.init.yml`: create `/config/jellyfin` and `/config/watchstate`.

`.env` / `.env.example`:

| Variable | Purpose |
| :--- | :--- |
| `JELLYFIN_PORT` | Host port (default `8096`) |
| `WATCHSTATE_PORT` | Host port (default `8282`) |

No Jellyfin admin password in git. First-run wizard (or `/Startup/*` API) uses the existing local admin username from the stack; password is set at runtime and not committed.

## Pre-cutover snapshot (not the nightly job)

Before mutating Seerr/Maintainerr/Homarr:

```text
/home/river/backups/pre-jellyfin-2026-09-14/
  config/     # rsync of CONFIG_ROOT with the same excludes as backup-config.sh
  compose/    # docker-compose.yml, .env, .env.example, README.md
  RESTORE.txt # how to roll back
```

Nightly `backup-config.sh` already covers `${CONFIG_ROOT}/jellyfin` and `watchstate` once those dirs exist. No cron change required. Mention Jellyfin QSV and the `plex` profile in `/home/river/backups/RECOVERY.md`.

## Rollback

1. `cd ~/riverdale_server && git checkout main` (or revert the feature branch)
2. Restore `${CONFIG_ROOT}/seerr`, `maintainerr`, `homarr` from `/home/river/backups/pre-jellyfin-2026-09-14/config/`
3. `docker compose --profile plex up -d plex`
4. `docker compose stop jellyfin watchstate` (optional; or leave them stopped)
5. Optional: start Plex + WatchState and force-export Jellyfin play state back to Plex before discarding Jellyfin

Plex config is never overwritten by this project, so Plex libraries/watch history from *before* the trial remain.

## Data flow

```text
/mnt/media-storage/media/{movies,tv}
        │ (ro)
        ├─ plex (stopped, profile plex)
        └─ jellyfin (live)
               │
     WatchState (one-shot import)
               │
     Seerr + Maintainerr + Homarr
```

Clients: `http://jellyfin.lan` or `http://192.168.1.37:8096`. Add a DNS A record `jellyfin.lan` → `192.168.1.37` the same way as `sonarr.lan`. `watchstate.lan` the same if using the UI.

## Docs (repo)

Update `README.md`: Jellyfin as the media server, Plex as profile-gated rollback, domains, ports, directory tree, QSV note, WatchState one-way import, rollback pointer to `RESTORE.txt`.

## Verification

1. `jellyfin` healthy; `/health` 200; UI at `jellyfin.lan` and `:8096`
2. Movies and TV libraries list existing files (spot-check counts vs disk)
3. Direct play plus one transcode using `/dev/dri` (intel_gpu_top or jellyfin ffmpeg log shows QSV/VAAPI)
4. WatchState history matches Plex played flags for mapped users (spot-check a few titles)
5. Seerr: login via Jellyfin, existing requests still listed, availability scan against Jellyfin
6. Maintainerr: rules present after switch; no Plex connection required
7. `docker compose up -d` does **not** start `plex`; `docker compose --profile plex up -d plex` does
8. Snapshot exists under `/home/river/backups/pre-jellyfin-2026-09-14/`

## Risks

- Seerr user auth is Plex-based today; switching without linking Jellyfin users logs everyone out
- WatchState matching can miss items without TMDB/TVDB IDs — those stay unwatched in Jellyfin
- `jellyfin.lan` will NXDOMAIN until DNS is updated; `:8096` still works
- First library scan is CPU-heavy; do not stop Plex until import + scan have started
- HDR tone-mapping may need the LinuxServer OpenCL Intel docker-mod; SDR QSV does not
