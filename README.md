# Riverdale Media Server

A complete media server stack with automated downloading, streaming capabilities, and system monitoring using Docker Compose.

## 🎯 Overview

This setup provides a full-featured media server with the following capabilities:

- **Network-wide Ad Blocking** with Pi-hole (Isolated Stack)
- **Modern torrent UI** with Flood
- **Automated TV show management** with Sonarr
- **Automated movie management** with Radarr
- **Torrent indexer management** with Prowlarr
- **Media streaming** with Plex (with Intel QuickSync hardware acceleration)
- **Reverse proxy** with Traefik for clean domain access
- **System monitoring** with Glances
- **Container update monitoring** with WUD (What's Up Docker)

## 📁 Project Structure

```text
riverdale_server/
├── docker-compose.yml              # Main media server stack (Apps)
├── docker-compose.pihole.yml       # Dedicated Network & DNS stack (Pi-hole)
├── docker-compose.init.yml         # Init script for directories & permissions
├── .env                           # Environment variables
├── .env.example                   # Example environment file
├── scripts/                       # Utility scripts
└── README.md                      # This file
```

## 🌐 Network Access

All services are accessible via clean domain names through Traefik reverse proxy.

**Note:** We use `.lan` domains (instead of `.local`) to avoid mDNS conflicts.

### Main Services (via Traefik - Port 80)

| Service | Domain | Description |
| :--- | :--- | :--- |
| **Pi-hole** | `pihole.lan` | Ad blocking & Local DNS Admin |
| **Plex** | `plex.river.local` | Media streaming (or direct via IP) |
| **Flood** | `flood.lan` | Modern torrent UI |
| **Sonarr** | `sonarr.lan` | TV show management |
| **Radarr** | `radarr.lan` | Movie management |
| **Prowlarr** | `prowlarr.lan` | Torrent indexer management |
| **Glances** | `glances.lan` | System monitoring |
| **Traefik** | `traefik.lan` | Reverse proxy dashboard |
| **WUD** | `wud.lan` | Container update monitoring |
| **Whoami** | `whoami.lan` | Traefik routing test |

### Direct Port Access

| Service | URL | Port | Notes |
| :--- | :--- | :--- | :--- |
| **Pi-hole** | `http://localhost:8053` | 8053 | DNS Admin |
| **Plex** | `http://localhost:32400/web` | 32400 | Media streaming |
| **Flood** | `http://localhost:3000` | 3000 | Torrent UI |
| **Transmission** | `http://localhost:9091` | 9091 | Torrent client |
| **Sonarr** | `http://localhost:8989` | 8989 | TV management |
| **Radarr** | `http://localhost:7878` | 7878 | Movie management |
| **Prowlarr** | `http://localhost:9696` | 9696 | Indexers |
| **Glances** | `http://localhost:61208` | 61208 | System monitoring |
| **Traefik** | `http://localhost:8080` | 8080 | Proxy dashboard |
| **WUD** | `http://localhost:3100` | 3100 | Update monitoring |

## 📋 Service Details

### Network Stack (`docker-compose.pihole.yml`)

- **Pi-hole**: DNS sinkhole and DHCP server. It manages the `riverdale_network` to ensure DNS stays up even if the main application stack is restarted.

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

## 🔧 Prerequisites

- Docker and Docker Compose installed
- Sufficient storage space for media and downloads
- Intel CPU with QuickSync support (optional, for Plex hardware transcoding)

## 📁 Directory Structure

Data Storage (configured in `.env`):

```text
├── /mnt/media-storage/config/     # Application configurations
│   ├── pihole/
│   ├── plex/
│   ├── sonarr/
│   ├── radarr/
│   ├── prowlarr/
│   ├── transmission/
│   ├── flood/
│   ├── traefik/
│   ├── glances/
│   └── wud/
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

```
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
│         Managed by: docker-compose.pihole.yml           │
│         Subnet: 172.19.0.0/16                           │
│                                                         │
│  ┌──────────────┐     ┌─────────────────────────────┐   │
│  │  Net Stack   │     │   Media Services            │   │
│  │  Pi-hole     │ ──► │   Plex, Transmission,       │   │
│  │              │     │   Flood, Sonarr, Radarr...  │   │
│  └──────────────┘     └─────────────────────────────┘   │
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

# Pi-hole
PIHOLE_PASSWORD=your_dns_password
```

### DNS Configuration

To use the `.lan` domains, you must use Pi-hole as your DNS server.

1. **Configure Client**: Set your computer's DNS to the server's IP address.
2. **Add Records**: In Pi-hole Admin (`http://<IP>:8053/admin`) -> **Local DNS** -> **DNS Records**:
    - `pihole.lan` -> `<Server IP>`
    - `sonarr.lan` -> `<Server IP>`
    - `radarr.lan` -> `<Server IP>`
    - ... etc

## 🚀 Getting Started

### Quick Start (Recommended)

1. **Initialize directories** (first time only):

   ```bash
   docker compose -f docker-compose.init.yml up
   ```

2. **Start Network/DNS Stack** (Pi-hole must run first):

   ```bash
   docker compose -f docker-compose.pihole.yml up -d
   ```

3. **Start Main Media Server**:

   ```bash
   docker compose up -d
   ```

### Docker Compose Commands

```bash
docker compose up -d              # Start main services
docker compose down               # Stop main services (Pi-hole stays up)
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

1. Ensure you are using the Pi-hole IP as your DNS.
2. Ensure you added the Local DNS records in Pi-hole.
3. Try `nslookup sonarr.lan <Server-IP>` to verify resolution.

### Glances or Web Interface Redirects to Google Search

- Type `http://glances.lan` explicitly.
- Or add a trailing slash `glances.lan/`.
