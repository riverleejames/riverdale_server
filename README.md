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
- **System monitoring** with Glances and Beszel
- **Service dashboard** with Dashy
- **Container update monitoring** with WUD (What's Up Docker)

## 📁 Project Structure

```
riverdale_server/
├── docker-compose.yml              # Main media server stack
├── .env                           # Environment variables
├── .env.example                   # Example environment file
├── scripts/                       # Utility scripts
└── README.md                      # This file
```

## 🌐 Network Access

All services are accessible via clean domain names through Traefik reverse proxy:

### Main Services (via Traefik - Port 80)

| Service | Domain | Description |
|---------|--------|-------------|
| **Plex** | `plex.river.local` | Media streaming server |
| **Flood** | `flood.river.local` | Modern torrent UI |
| **Sonarr** | `sonarr.river.local` | TV show management |
| **Radarr** | `radarr.river.local` | Movie management |
| **Prowlarr** | `prowlarr.river.local` | Torrent indexer management |
| **Glances** | `glances.river.local` | System monitoring |
| **Dashy** | `dashy.river.local` | Service dashboard |
| **Traefik** | `traefik.river.local` | Reverse proxy dashboard |
| **WUD** | `wud.river.local` | Container update monitoring |
| **Beszel** | `beszel.river.local` | Advanced system monitoring |

### Direct Port Access

| Service | URL | Port | Notes |
|---------|-----|------|-------|
| **Plex** | `http://localhost:32400/web` | 32400 | Media streaming |
| **Flood** | `http://localhost:3000` | 3000 | Torrent UI |
| **Transmission** | `http://localhost:9091` | 9091 | Torrent client |
| **Sonarr** | `http://localhost:8989` | 8989 | TV management |
| **Radarr** | `http://localhost:7878` | 7878 | Movie management |
| **Prowlarr** | `http://localhost:9696` | 9696 | Indexers |
| **Dashy** | `http://localhost:4000` | 4000 | Dashboard |
| **Glances** | `http://localhost:61208` | 61208 | System monitoring |
| **Traefik** | `http://localhost:8080` | 8080 | Proxy dashboard |
| **WUD** | `http://localhost:3100` | 3100 | Update monitoring |
| **Beszel** | `http://localhost:8090` | 8090 | Advanced monitoring |

## 📋 Service Details

### Main Media Server Stack (`docker-compose.yml`)

- **Transmission**: Torrent client
- **Flood**: Modern web UI for Transmission
- **Plex** (32400): Media streaming with Intel QuickSync hardware acceleration
- **Sonarr** (8989): Automated TV show downloading and management
- **Radarr** (7878): Automated movie downloading and management
- **Prowlarr** (9696): Torrent indexer management and integration
- **Traefik** (80/8080): Reverse proxy for clean domain access
- **Dashy** (4000): Customizable dashboard for all services
- **Glances** (61208): Real-time system monitoring
- **Beszel** (8090): Advanced system monitoring with agent-based architecture
- **WUD** (3100): Container update monitoring with web UI
- **Whoami**: Test service for Traefik routing

## 🔧 Prerequisites

- Docker and Docker Compose installed
- Sufficient storage space for media and downloads
- Intel CPU with QuickSync support (optional, for Plex hardware transcoding)

## 📁 Directory Structure

```
Data Storage (configured in .env):
├── /mnt/media-storage/config/     # Application configurations
│   ├── plex/
│   ├── sonarr/
│   ├── radarr/
│   ├── prowlarr/
│   ├── transmission/
│   ├── flood/
│   ├── traefik/
│   ├── dashy/
│   ├── glances/
│   ├── wud/
│   └── beszel/
├── /mnt/media-storage/downloads/  # Download staging
│   ├── complete/
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
Traefik Reverse Proxy (Port 80) - *.river.local domains
    ↓
┌─────────────────────────────────────────────────────────┐
│         Docker Network (riverdale_network)              │
│         Subnet: 172.19.0.0/16                           │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │   Media Services                                 │  │
│  │   Plex, Transmission, Flood, Sonarr,             │  │
│  │   Radarr, Prowlarr, Dashy, Glances,              │  │
│  │   WUD, Traefik, Beszel, Whoami                   │  │
│  └──────────────────────────────────────────────────┘  │
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
DASHY_PORT=4000
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

# Traefik External Access (Optional)
DOMAIN=your-domain.duckdns.org
EMAIL=your-email@example.com
TRAEFIK_BASIC_AUTH_USER=your_username
TRAEFIK_BASIC_AUTH_PASSWORD_HASH=$$2y$$05$$YourHashHere

# Beszel Monitoring
BESZEL_TOKEN=your-beszel-token
BESZEL_KEY=your-ssh-key
```

### DNS Configuration (Optional)

For clean `.river.local` domain names, you have two options:

#### Option 1: Local DNS Server (Pi-hole, AdGuard Home, etc.)

Add DNS records pointing all `*.river.local` domains to your server's IP address.

#### Option 2: /etc/hosts File

Add entries to `/etc/hosts` on each client device:

```
YOUR_SERVER_IP    plex.river.local
YOUR_SERVER_IP    flood.river.local
YOUR_SERVER_IP    sonarr.river.local
YOUR_SERVER_IP    radarr.river.local
YOUR_SERVER_IP    prowlarr.river.local
YOUR_SERVER_IP    dashy.river.local
YOUR_SERVER_IP    glances.river.local
YOUR_SERVER_IP    traefik.river.local
YOUR_SERVER_IP    beszel.river.local
YOUR_SERVER_IP    wud.river.local
```

**Note**: If not using DNS, you can access services via direct ports (see Network Access section).

## 🚀 Getting Started

### Quick Start (Recommended)

Use the included management script for easy setup:

1. **Initialize directories** (first time only):
   ```bash
   ./manage.sh init
   ```

2. **Start main media server**:
   ```bash
   docker compose up -d
   ```

3. **Check status**:
   ```bash
   docker compose ps
   ```

### Docker Compose Commands

Common docker compose commands:

```bash
docker compose up -d              # Start all services
docker compose down               # Stop all services
docker compose restart            # Restart all services
docker compose logs -f [service]  # View logs
docker compose ps                 # Show container status
docker compose pull               # Update images
```

### First-Time Access

After starting services, wait 2-3 minutes for health checks, then access:

- **Dashboard**: http://dashy.river.local (or http://localhost:4000)
- **Media Server**: http://plex.river.local (or http://localhost:32400/web)
- **Torrents**: http://flood.river.local (or http://localhost:3000)
- **Monitoring**: http://beszel.river.local (or http://localhost:8090)

## 📱 Initial Service Configuration

### 1. Flood (Torrent UI)

Access http://flood.river.local and configure:

- **Client Type**: Transmission
- **Hostname**: `transmission`
- **Port**: `9091`
- **Username**: Your USERNAME from .env
- **Password**: Your PASSWORD from .env
- **URL Path**: `/transmission/rpc`

### 2. Prowlarr (Indexer Management)

1. Access http://prowlarr.river.local
2. Add your torrent indexers
3. Connect to Sonarr and Radarr (will auto-detect on network)

### 3. Sonarr (TV Shows)

1. Access http://sonarr.river.local
2. Settings → Download Clients → Add Transmission
3. Host: `transmission`, Port: `9091`
4. Add root folder: `/tv`

### 4. Radarr (Movies)

1. Access http://radarr.river.local
2. Settings → Download Clients → Add Transmission
3. Host: `transmission`, Port: `9091`
4. Add root folder: `/movies`

### 5. Plex (Media Server)

1. Access http://plex.river.local or http://localhost:32400/web
2. Sign in with your Plex account
3. Complete initial setup wizard
4. Add media libraries:
   - Movies: `/media/movies`
   - TV Shows: `/media/tv`
5. Hardware transcoding is automatically enabled (Intel QuickSync)

### 6. Beszel (System Monitoring)

1. Access http://beszel.river.local or http://localhost:8090
2. Complete initial setup
3. The agent is automatically connected and monitoring system resources

## 🔒 Security & Stability Features

### Security

- **User Isolation**: Services run with specified PUID/PGID
- **Health Checks**: All services monitored for proper operation
- **Network Isolation**: Services communicate via Docker bridge network
- **Traefik Integration**: Centralized reverse proxy with optional authentication

### Stability Improvements

- **Health-Based Checks**: Services have proper startup time and monitoring
- **Resource Management**: Efficient container resource allocation
- **Proper Dependencies**: Services start in correct order
- **Automated Recovery**: Containers restart automatically on failure

## 🔄 Container Updates & Maintenance

### WUD - What's Up Docker (Update Monitoring)

**WUD** monitors your containers for available updates:

- **Schedule**: Checks daily at 4:00 AM
- **Web UI**: Visual dashboard at `http://wud.river.local` or `http://localhost:3100`
- **Update Detection**: Automatically detects new versions for all containers
- **Notification Support**: Can trigger notifications via webhooks, email, etc.
- **Flexible Updates**: Unlike Watchtower, WUD focuses on monitoring and lets you control updates

Access the WUD dashboard to see which containers have updates available. You can then manually update containers or configure triggers for automatic updates.

### Management Commands

```bash
# Docker Compose commands
docker compose up -d           # Start all services
docker compose down            # Stop all services
docker compose restart         # Restart all services
docker compose logs -f         # Follow logs
docker compose ps              # Check status
docker compose pull            # Pull latest images
```

## 🎬 Initial Setup Workflow

1. **Start services**: `docker compose up -d`
2. **Setup Dashy Dashboard**: Access http://dashy.river.local and configure service tiles
3. **Configure Prowlarr**: Add torrent indexers at http://prowlarr.river.local
4. **Setup Sonarr**: Configure quality profiles and connect to Prowlarr at http://sonarr.river.local
5. **Setup Radarr**: Configure quality profiles and connect to Prowlarr at http://radarr.river.local
6. **Configure Transmission**: Set download directories and preferences at http://transmission.river.local:9091
7. **Setup Plex**: Add media libraries and claim server at http://plex.river.local

## �️ Dashy Dashboard Configuration

**Dashy** provides a beautiful, customizable dashboard to manage all your services:

### Adding Service Tiles

1. **Access Dashy**: Navigate to <http://dashy.river.local>
2. **Enter Edit Mode**: Click the edit icon (pencil) in the top right
3. **Add Services**: Use these configurations for your tiles:

```yaml
sections:
  - name: Media Services
    items:
      - title: Plex
        url: http://plex.river.local
        icon: hl-plex
      - title: Sonarr
        url: http://sonarr.river.local
        icon: hl-sonarr
      - title: Radarr
        url: http://radarr.river.local
        icon: hl-radarr
      - title: Prowlarr
        url: http://prowlarr.river.local
        icon: hl-prowlarr
        
  - name: Downloads
    items:
      - title: Flood
        url: http://flood.river.local
        icon: hl-flood
      - title: Transmission
        url: http://transmission.river.local:9091
        icon: hl-transmission
        
  - name: System
    items:
      - title: Glances
        url: http://glances.river.local
        icon: hl-glances
      - title: Beszel
        url: http://beszel.river.local
        icon: hl-beszel
      - title: Traefik
        url: http://traefik.river.local
        icon: hl-traefik
      - title: WUD
        url: http://wud.river.local
        icon: hl-wud
```

### Advanced Features

- **Status Indicators**: Enable health checks for real-time service status
- **Custom Widgets**: Add system info, weather, or other widgets
- **Themes**: Choose from multiple built-in themes or create custom ones
- **Mobile Support**: Responsive design works great on mobile devices

## 🎬 Hardware Acceleration (Plex)

Plex is configured for Intel QuickSync hardware acceleration:

- **Requirements**: Intel CPU with integrated graphics (6th gen or newer)
- **Devices**: `/dev/dri` directory mapped to container
- **Benefits**: 10x faster transcoding, lower CPU usage
- **Codecs**: Hardware H.264, H.265, VP9 encoding/decoding

**Configuration:**

1. Hardware transcoding is automatically enabled when Plex detects Intel QuickSync
2. Access Settings → Transcoder to verify hardware transcoding is active
3. Requires Plex Pass subscription for hardware transcoding features

## 🚨 Troubleshooting

### Transmission/Flood Not Working

```bash
# Check if Transmission is accessible
curl http://localhost:9091

# Check Flood logs
docker compose logs flood

# Verify Flood can reach Transmission
docker exec flood curl http://transmission:9091
```

**Common fixes:**
- Verify credentials match in Flood and `.env`
- Hostname in Flood configuration must be `transmission`
- Ensure both containers are on the same network

### Service Won't Start

```bash
# Check container status
docker compose ps

# View specific service logs
docker compose logs [service_name]

# Check all logs
docker compose logs -f
```

**Common fixes:**
- Wait for health checks (some services take 2-3 minutes)
- Check PUID/PGID permissions
- Ensure required directories exist and are writable
- Verify `.env` file exists and is properly configured

### Permission Issues

```bash
# Check directory ownership
ls -la /mnt/media-storage/config/

# Fix permissions (replace 1000:1000 with your PUID:PGID)
sudo chown -R 1000:1000 /mnt/media-storage/config
sudo chown -R 1000:1000 /mnt/media-storage/downloads
sudo chown -R 1000:1000 /mnt/media-storage/media

# Create directories if missing
mkdir -p /mnt/media-storage/{config,downloads,media}
```

### Plex Issues

```bash
# Check Plex logs
docker compose logs plex

# Verify hardware acceleration
docker exec plex ls -la /dev/dri

# Check Plex claim token
echo $PLEX_CLAIM
```

**Common fixes:**
- Ensure Plex claim token is valid (get new one from plex.tv/claim)
- Verify `/dev/dri` devices are accessible
- Check media directories are properly mounted
- Allow 2-3 minutes for Plex to fully initialize

### Health Check Failures

```bash
# See which services are unhealthy
docker ps --filter "health=unhealthy"

# Check specific health check logs
docker inspect [container_name] | grep -A 10 Health
```

**Common fixes:**
- Wait longer (some services need 5+ minutes on first start)
- Check service-specific logs for errors
- Restart individual service: `docker-compose restart [service]`

### Storage/Disk Space Issues

```bash
# Check disk usage
df -h ${DATA_ROOT}

# Check Docker disk usage
docker system df

# Clean up old images
docker image prune -a
```

## 📝 Important Notes

### Architecture Design

- **Health-Based Startup**: Services wait for dependencies to be healthy
- **Resource Efficiency**: Services run with minimal overhead
- **Network Isolation**: Services communicate via Docker bridge network

### Service Dependencies

```
Main Stack Dependencies:
  Sonarr, Radarr → Prowlarr
  Flood → Transmission
  All web services → Traefik (for routing)
```

### Resource Requirements

- **Media Server**: 4GB RAM minimum, 8GB recommended
- **Storage**: Depends on media library size
- **CPU**: Intel with QuickSync recommended for Plex hardware transcoding

### Backup Recommendations

Essential data to backup regularly:

```bash
# Application configurations
/mnt/media-storage/config/*

# Environment variables
.env

# Docker Compose file
docker-compose.yml

# Media library metadata (optional)
/mnt/media-storage/media/*
```

### Port Reference

| Service | Internal Port | External Port | Protocol |
|---------|--------------|---------------|----------|
| Traefik | 80 | 80 | HTTP |
| Traefik Dashboard | 8080 | 8080 | HTTP |
| Plex | 32400 | 32400 | HTTP |
| Flood | 3000 | 3000 | HTTP |
| Transmission | 9091 | 9091 | HTTP |
| Sonarr | 8989 | 8989 | HTTP |
| Radarr | 7878 | 7878 | HTTP |
| Prowlarr | 9696 | 9696 | HTTP |
| Dashy | 4000 | 4000 | HTTP |
| Glances | 61208 | 61208 | HTTP |
| WUD | 3100 | 3100 | HTTP |
| Beszel | 8090 | 8090 | HTTP |

## 🔧 Advanced Configuration

### WUD Update Check Scheduling

Edit docker-compose.yml to change when WUD checks for updates:

```yaml
wud:
  environment:
    - WUD_WATCHER_LOCAL_CRON=0 2 * * *  # 2 AM instead of default
```

### Plex Hardware Transcoding

Ensure your system has Intel QuickSync support:

```bash
# Check for hardware video devices
ls -la /dev/dri

# Should show renderD128 and card devices
```

## 🤝 Getting Help

### Logs for Debugging

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f plex

# Last 100 lines
docker compose logs --tail=100

# Since specific time
docker compose logs --since 30m
```

### Container Status

```bash
# Quick status
docker compose ps

# Detailed info
docker compose ps -a

# Resource usage
docker stats
```

### Health Checks

```bash
# See health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Detailed health info
docker inspect plex | grep -A 20 Health
```

## 📚 Additional Resources

- **Plex Docs**: https://support.plex.tv/
- **Flood UI**: https://github.com/jesec/flood
- **Sonarr Wiki**: https://wiki.servarr.com/sonarr
- **Radarr Wiki**: https://wiki.servarr.com/radarr
- **Prowlarr Wiki**: https://wiki.servarr.com/prowlarr
- **Traefik Docs**: https://doc.traefik.io/traefik/
- **WUD Docs**: https://getwud.github.io/wud/
- **Beszel Docs**: https://github.com/henrygd/beszel
- **Transmission**: https://transmissionbt.com/
- **Dashy**: https://dashy.to/

## 📄 License

This configuration is provided as-is for personal use. Always respect copyright and licensing requirements for media content.
