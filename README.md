# Riverdale Media Server

A complete media server stack with automated downloading, streaming capabilities, and system monitoring using Docker Compose.

## 🎯 Overview

This setup provides a full-featured media server with the following capabilities:

- **Modern torrent UI** with Flood
- **Automated TV show management** with Sonarr
- **Automated movie management** with Radarr
- **Torrent indexer management** with Prowlarr
- **Media streaming** with Plex (with Intel QuickSync hardware acceleration)
- **Reverse proxy** with Traefik for clean domain access
- **System monitoring** with Glances
- **Container update monitoring** with WUD (What's Up Docker)
- **Unified dashboard** with Homarr
- **Push notifications** with ntfy (Sonarr, Radarr, Prowlarr, Maintainerr, WUD)
- **Automatic subtitles** with Bazarr
- **Automated quality profile/custom format sync** with Recyclarr (TRaSH Guides)

## 📁 Project Structure

```text
riverdale_server/
├── docker-compose.yml              # Main media server stack (Apps)
├── docker-compose.init.yml         # Init script for directories & permissions
├── .env                           # Environment variables
├── .env.example                   # Example environment file
└── README.md                      # This file
```

## 🌐 Network Access

Most services are accessible via clean domain names through Traefik reverse proxy.

**Note:** We use `.lan` domains (instead of `.local`) to avoid mDNS conflicts.
**Note:** Plex runs in host mode and is accessed directly (not through Traefik).

### Main Services (via Traefik - Port 80)

| Service | Domain | Description |
| :--- | :--- | :--- |
| **Flood** | `flood.lan` | Modern torrent UI |
| **Sonarr** | `sonarr.lan` | TV show management |
| **Radarr** | `radarr.lan` | Movie management |
| **Prowlarr** | `prowlarr.lan` | Torrent indexer management |
| **Glances** | `glances.lan` | System monitoring |
| **Traefik** | `traefik.lan` | Reverse proxy dashboard |
| **WUD** | `wud.lan` | Container update monitoring |
| **Homarr** | `homarr.lan` | Unified services dashboard |
| **ntfy** | `ntfy.lan` | Push notifications |
| **Bazarr** | `bazarr.lan` | Subtitle management |
| **Whoami** | `whoami.lan` | Traefik routing test |

### Direct Port Access

| Service | URL | Port | Notes |
| :--- | :--- | :--- | :--- |
| **Plex** | `http://localhost:32400/web` | 32400 | Media streaming |
| **Flood** | `http://localhost:3000` | 3000 | Torrent UI |
| **Transmission** | `http://localhost:9091` | 9091 | Torrent client |
| **Sonarr** | `http://localhost:8989` | 8989 | TV management |
| **Radarr** | `http://localhost:7878` | 7878 | Movie management |
| **Prowlarr** | `http://localhost:9696` | 9696 | Indexers |
| **Glances** | `http://localhost:61208` | 61208 | System monitoring |
| **Traefik** | `http://localhost:8080` | 8080 | Proxy dashboard |
| **WUD** | `http://localhost:3100` | 3100 | Update monitoring |
| **Homarr** | `http://localhost:7575` | 7575 | Services dashboard |
| **ntfy** | `http://localhost:8090` | 8090 | Push notifications |
| **Bazarr** | `http://localhost:6767` | 6767 | Subtitle management |

## 📋 Service Details

### Main Media Server Stack (`docker-compose.yml`)

- **Transmission**: Torrent client
- **Flood**: Modern web UI for Transmission
- **Plex** (32400): Media streaming with Intel QuickSync hardware acceleration
- **Sonarr** (8989): Automated TV show downloading and management
- **Radarr** (7878): Automated movie downloading and management
- **Prowlarr** (9696): Torrent indexer management and integration
- **Traefik** (80/8080): Reverse proxy for clean domain access
- **Glances** (61208): Real-time system monitoring
- **WUD** (3100): Container update monitoring with web UI
- **Homarr** (7575): Unified dashboard for all services (V2 public beta image `homarr-test:v2`; Workshop via `WORKSHOP_API_URL`)
- **ntfy** (8090): Self-hosted push notifications, wired into Sonarr, Radarr, Prowlarr, Maintainerr and WUD
- **Bazarr** (6767): Automatic subtitle downloads for Sonarr/Radarr
- **Recyclarr**: No web UI. Headless container that syncs TRaSH Guides custom formats and quality-size definitions into Sonarr/Radarr on a daily schedule

## 🔧 Prerequisites

- Docker and Docker Compose installed
- Sufficient storage space for media and downloads
- Intel CPU with QuickSync support (optional, for Plex hardware transcoding)

## 📁 Directory Structure

Data Storage (configured in `.env`):

```text
├── /mnt/media-storage/config/     # Application configurations
│   ├── plex/
│   ├── sonarr/
│   ├── radarr/
│   ├── prowlarr/
│   ├── transmission/
│   ├── flood/
│   ├── traefik/
│   ├── glances/
│   ├── wud/
│   ├── homarr/
│   ├── ntfy/
│   ├── bazarr/
│   └── recyclarr/
├── /mnt/media-storage/downloads/  # Download staging
│   ├── complete/
│   │   ├── movies/
│   │   ├── tv/
│   │   ├── tv-sonarr/        # Explicitly mapped for Sonarr
│   │   └── radarr/           # Explicitly mapped for Radarr
│   ├── incomplete/
│   └── watch/
└── /mnt/media-storage/media/      # Final media storage
    ├── movies/
    └── tv/
```

## 🌐 Network Architecture

```text
Internet
    ↓
Router
    ↓
Your Local Network
    ↓
Traefik Reverse Proxy (Port 80) - *.lan domains
    ↓
┌─────────────────────────────────────────────────────────┐
│         Docker Network (riverdale_network)              │
│         Subnet: 172.19.0.0/16                           │
│                                                         │
│  ┌───────────────────────────────────────────────────┐   │
│  │   Media Services                                  │   │
│  │   Plex, Transmission, Flood, Sonarr, Radarr...   │   │
│  └───────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## ⚙️ Configuration

### Environment Variables

Copy `.env.example` to `.env` and update with your specific values:

```bash
# User/Group IDs (run 'id' command to get your values)
PUID=1000
PGID=1000

# Timezone
TZ=Europe/Dublin

# Storage Paths
DATA_ROOT=/mnt/media-storage
CONFIG_ROOT=/mnt/media-storage/config
DOWNLOADS_ROOT=/mnt/media-storage/downloads
MEDIA_ROOT=/mnt/media-storage/media

# Service Ports
FLOOD_PORT=3000
PLEX_PORT=32400
SONARR_PORT=8989
RADARR_PORT=7878
TRANSMISSION_PORT=9091
PROWLARR_PORT=9696
GLANCES_PORT=61208

# Transmission/Flood Authentication
USERNAME=your_username
PASSWORD=your_password

# Plex Configuration
PLEX_CLAIM=claim-your-token-here
```

### DNS Configuration

To use the `.lan` domains, configure your DNS server to resolve local hostnames to your media server IP.

1. **Configure Client**: Set your computer/router DNS to a resolver you control (router DNS, AdGuard Home, Unbound, etc.).
2. **Add Records**: Create local DNS records for your services:
    - `sonarr.lan` -> `<Server IP>`
    - `radarr.lan` -> `<Server IP>`
    - `flood.lan` -> `<Server IP>`
    - ... etc

## 🚀 Getting Started

### Quick Start (Recommended)

1. **Initialize directories** (first time only):

   ```bash
   docker compose -f docker-compose.init.yml up
   ```

2. **Start Main Media Server**:

   ```bash
   docker compose up -d
   ```

### Docker Compose Commands

```bash
docker compose up -d              # Start main services
docker compose down               # Stop main services
docker compose logs -f [service]  # View logs
```

## 📱 Service Configuration

### 1. Flood (Torrent UI)

Access <http://flood.lan> and configure:

- **Client Type**: Transmission
- **Hostname**: `transmission`
- **Port**: `9091`
- **Username**: Your USERNAME from .env
- **Password**: Your PASSWORD from .env
- **URL Path**: `/transmission/rpc`

### 2. Prowlarr (Indexer Management)

1. Access <http://prowlarr.lan>
2. Add your torrent indexers
3. Connect to Sonarr and Radarr (will auto-detect on network)

### 3. Sonarr (TV Shows)

1. Access <http://sonarr.lan>
2. Settings → Download Clients → Add Transmission
3. Host: `transmission`, Port: `9091`
4. Add root folder: `/tv`

### 4. Radarr (Movies)

1. Access <http://radarr.lan>
2. Settings → Download Clients → Add Transmission
3. Host: `transmission`, Port: `9091`
4. Add root folder: `/movies`

### 5. Plex (Media Server)

1. Access <http://localhost:32400/web>
2. Sign in with your Plex account
3. Complete initial setup wizard
4. Add media libraries:
   - Movies: `/media/movies`
   - TV Shows: `/media/tv`

### 6. ntfy (Push Notifications)

Self-hosted at `http://ntfy.lan` (no auth by default, LAN-only). Sonarr, Radarr, Prowlarr, Maintainerr and WUD are already wired up to publish to it, each on its own topic:

| Service | Topic | Fires on |
| :--- | :--- | :--- |
| Sonarr | `riverdale-sonarr` | Download/upgrade complete, health issues, app updates, manual intervention needed |
| Radarr | `riverdale-radarr` | Same as Sonarr |
| Prowlarr | `riverdale-prowlarr` | Indexer health issues, app updates |
| Maintainerr | `riverdale-maintainerr` | Rule/collection handling failures, update available |
| WUD | `riverdale-updates` | A container has an image update available |

To get these on your phone:

1. Install the **ntfy** app ([Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy) / [iOS](https://apps.apple.com/us/app/ntfy/id1625396347)).
2. In the app, set **Settings → Default server** to `http://ntfy.lan` (or `http://<Server-IP>:8090`).
3. Subscribe to each topic above you want alerts for (add one subscription per topic). Only works while your phone can reach the server (same LAN, or a VPN back into it — there's no port-forwarding/remote access configured for it here).

**Seerr and Homarr also support ntfy, but need a one-time UI step** (their settings pages require a logged-in admin session, not just an API key, so they can't be scripted):

- **Seerr**: Settings → Notifications → ntfy.sh. Server URL: `http://ntfy:80`, pick a topic (e.g. `riverdale-seerr`), enable the request/availability events you want.
- **Homarr**: Settings → Integrations → Add integration → Ntfy. URL: `http://ntfy:80`, Topic: whichever topic(s) you want visible on the dashboard. Then add the **Notifications** widget to a board and point it at that integration to see history alongside your other widgets (this is a dashboard view, separate from the phone push above).

### 7. Bazarr (Subtitles)

Already connected to Sonarr and Radarr, with an English language profile created and assigned to every existing series/movie, so anything already in your library will start picking up subtitles automatically.

**One manual step left**: no subtitle provider is enabled yet, so searches currently find nothing. Access <http://bazarr.lan> → Settings → Providers → add one or more. Most people use **OpenSubtitles.com** (free account required, best coverage); a no-signup option like **Podnapisi** also works but with less reliable English coverage.

### 8. Recyclarr (Quality Profile Automation)

Runs automatically once a day (no setup needed) and keeps two things in sync from the [TRaSH Guides](https://trash-guides.info/) for both Sonarr and Radarr's `Any` profile:

- **Custom formats**: rejects junk releases (BR-DISK, upscaled, low-quality release groups/titles, 3D, extras) with a -10000 score, same pattern as the pre-existing "Reject - Executable Bait" format.
- **Quality size limits**: keeps the min/max file size per quality tier (e.g. 2160p) aligned with TRaSH's curated values, so raising a resolution cap never means an unbounded/"massive" file can be grabbed.

Config lives at `${CONFIG_ROOT}/recyclarr/recyclarr.yml`. To change what it manages (e.g. add more custom formats, or target a different profile), edit that file — it takes effect on the next scheduled sync, or immediately with:

```bash
docker exec recyclarr recyclarr sync --preview   # see what would change first
docker exec recyclarr recyclarr sync              # apply
```

**Note on 4K**: as part of setting this up, the `Any` quality profile on both Sonarr and Radarr was changed to allow 2160p WEB/Bluray (previously blocked entirely on Sonarr; Radarr already allowed WEB-2160p). Remux is intentionally left disabled on both (too large), and every 2160p tier has a real max-size cap so a single episode/movie can't balloon past a few GB.

### 9. Maintainerr (Watched-Content Cleanup)

Beyond the original "delete watched movies / seasons after 7 days" rules, two changes were made:

- **Episode-level cleanup**: TV cleanup now happens per-episode instead of waiting for a whole season to be watched (the old "Watched TV Seasons" rule is disabled, not deleted, in case you want to revert).
- **Emergency low-disk cleanup**: two additional rule groups (`Emergency Low Disk Cleanup - Movies` / `- TV Episodes`) skip the normal 7-day grace period entirely for already-watched content once the media disk drops below 50GB free, deleting it immediately instead. They do nothing while disk space is healthy.

All of this is configured through Maintainerr's own database (Settings → Rules in the UI), not through files in this repo.

## 🚨 Troubleshooting

### Transmission/Flood Not Working

```bash
# Check Flood logs
docker compose logs flood

# Verify Flood can reach Transmission
docker exec flood curl http://transmission:9091
```

### "DNS_PROBE_FINISHED_NXDOMAIN"

If `.lan` domains don't work:

1. Ensure your DNS resolver has local records for your `.lan` domains.
2. Ensure clients are actually using that resolver.
3. Try `nslookup sonarr.lan <Server-IP>` to verify resolution.

If Plex is reachable by IP/localhost but not by hostname, that is expected unless you create a separate DNS record for Plex and route it independently.

### Glances or Web Interface Redirects to Google Search

- Type `http://glances.lan` explicitly.
- Or add a trailing slash `glances.lan/`.
