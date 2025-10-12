# Riverdale Media Server

A complete media server stack with automated downloading, VPN protection, streaming capabilities, Minecraft server, and Windows 11 VM using Docker Compose with a modular architecture.

## 🎯 Overview

This setup provides a full-featured media server with the following capabilities:

- **Secure torrenting** through VPN (Gluetun with NordVPN)
- **Modern torrent UI** with Flood
- **Automated TV show management** with Sonarr
- **Automated movie management** with Radarr
- **Torrent indexer management** with Prowlarr
- **Media streaming** with Jellyfin (with Intel QuickSync hardware acceleration)
- **Reverse proxy** with Traefik for clean domain access
- **System monitoring** with Glances
- **Service dashboard** with Dashy
- **Automatic updates** with Watchtower
- **Minecraft Bedrock server** for mobile/tablet play (separate stack)
- **Windows 11 VM** via Docker (separate stack)
- **Dynamic DNS** with DuckDNS for external access

## 📁 Modular Architecture

This server uses **multiple docker-compose files** for better organization and independent management:

```
riverdale_server/
├── docker-compose.yml              # Main media server stack
├── docker-compose.init.yml         # One-time directory initialization
├── docker-compose.minecraft.yml    # Minecraft Bedrock server (optional)
├── docker-compose.windows.yml      # Windows 11 VM (optional)
├── manage.sh                       # Convenient management script
├── .env                           # Environment variables (shared by all)
└── README.md                      # This file
```

### File Purposes

- **`docker-compose.yml`**: Core media services (Jellyfin, Sonarr, Radarr, VPN, etc.)
- **`docker-compose.init.yml`**: Directory creation with proper permissions (run once)
- **`docker-compose.minecraft.yml`**: Minecraft server (start/stop independently)
- **`docker-compose.windows.yml`**: Windows 11 VM (8GB RAM, start when needed)
- **`manage.sh`**: Script to easily manage all docker-compose files

## 🌐 Network Access

All services are accessible via clean domain names through Traefik reverse proxy:

### Main Services (via Traefik - Port 80)

| Service | Domain | Description |
|---------|--------|-------------|
| **Jellyfin** | `jellyfin.river.local` | Media streaming server |
| **Flood** | `flood.river.local` | Modern torrent UI |
| **Sonarr** | `sonarr.river.local` | TV show management |
| **Radarr** | `radarr.river.local` | Movie management |
| **Prowlarr** | `prowlarr.river.local` | Torrent indexer management |
| **Glances** | `glances.river.local` | System monitoring |
| **Dashy** | `dashy.river.local` | Service dashboard |
| **Traefik** | `traefik.river.local` | Reverse proxy dashboard |

### Direct Port Access

| Service | URL | Port | Notes |
|---------|-----|------|-------|
| **Jellyfin** | `http://localhost:8096` | 8096 | Direct access |
| **Flood** | `http://localhost:3000` | 3000 | Torrent UI |
| **Transmission** | `http://localhost:9091` | 9091 | VPN-protected |
| **Sonarr** | `http://localhost:8989` | 8989 | TV management |
| **Radarr** | `http://localhost:7878` | 7878 | Movie management |
| **Prowlarr** | `http://localhost:9696` | 9696 | Indexers |
| **Dashy** | `http://localhost:4000` | 4000 | Dashboard |
| **Glances** | `http://localhost:61208` | 61208 | Monitoring |
| **Traefik** | `http://localhost:8080` | 8080 | Proxy dashboard |
| **Windows VM** | `http://localhost:8006` | 8006 | Web viewer |
| **Windows RDP** | `localhost:3389` | 3389 | Remote desktop |
| **Minecraft** | `YOUR_IP:19132` | 19132/UDP | Bedrock server |

## 📋 Service Details

### Main Media Server Stack (`docker-compose.yml`)

- **Gluetun**: VPN container (NordVPN Netherlands UDP)
- **Transmission**: Torrent client running through VPN
- **Flood**: Modern web UI for Transmission
- **Jellyfin** (8096): Media streaming with Intel QuickSync hardware acceleration
- **Sonarr** (8989): Automated TV show downloading and management
- **Radarr** (7878): Automated movie downloading and management
- **Prowlarr** (9696): Torrent indexer management and integration
- **Traefik** (80/8080): Reverse proxy for clean domain access
- **Dashy** (4000): Customizable dashboard for all services
- **Glances** (61208): Real-time system monitoring
- **Watchtower**: Automatic container updates (4 AM daily)
- **DuckDNS**: Dynamic DNS for external access
- **Whoami**: Test service for Traefik routing

### Optional Services

#### Minecraft Server (`docker-compose.minecraft.yml`)

- **Minecraft Bedrock**: Mobile/tablet compatible server
- **Port**: 19132/UDP (external access enabled)
- **Configuration**: Creative mode, peaceful difficulty, flat world for building
- **Access**: `YOUR_PUBLIC_IP:19132` or `river-minecraft.duckdns.org:19132`

#### Windows 11 VM (`docker-compose.windows.yml`)

- **Windows 11 Pro**: Full Windows VM in Docker
- **Resources**: 8GB RAM, 4 CPU cores, 128GB disk
- **Access**: Web viewer (http://localhost:8006) or RDP (localhost:3389)
- **Note**: Only run when needed due to resource usage

## 🔧 Prerequisites

- Docker and Docker Compose installed
- NordVPN account (or modify `.env` for other VPN providers)
- Sufficient storage space for media and downloads
- Intel CPU with QuickSync support (optional, for Jellyfin hardware transcoding)
- For Minecraft: Port forwarding on router (UDP 19132)
- For Windows VM: KVM support (`/dev/kvm` device)

## 📁 Directory Structure

```
riverdale_server/
├── docker-compose.yml              # Main media server
├── docker-compose.init.yml         # Directory initialization
├── docker-compose.minecraft.yml    # Minecraft server
├── docker-compose.windows.yml      # Windows 11 VM
├── manage.sh                       # Management script
├── .env                           # Environment variables
└── README.md                      # This file

Data Storage (configured in .env):
├── /mnt/media-storage/config/     # Application configurations
│   ├── jellyfin/
│   ├── sonarr/
│   ├── radarr/
│   ├── prowlarr/
│   ├── transmission/
│   ├── flood/
│   ├── gluetun/
│   ├── traefik/
│   ├── dashy/
│   ├── glances/
│   ├── watchtower/
│   ├── duckdns/
│   ├── minecraft/
│   └── windows/
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
Router (Port Forwarding for Minecraft: 19132/UDP)
    ↓
Your Local Network
    ↓
Traefik Reverse Proxy (Port 80) - *.river.local domains
    ↓
┌─────────────────────────────────────────────────────────┐
│         Docker Network (riverdale_network)              │
│         Subnet: 172.19.0.0/16                           │
│                                                         │
│  ┌─────────────┐  ┌──────────────────────────────┐     │
│  │   Gluetun   │  │   Other Services             │     │
│  │  (VPN UDP)  │  │  (Jellyfin, Sonarr, Radarr,  │     │
│  │      ├──────┼──│   Prowlarr, Flood, Dashy,    │     │
│  │ Transmission│  │   Glances, Traefik, DuckDNS) │     │
│  └─────────────┘  └──────────────────────────────┘     │
│                                                         │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │   Minecraft     │  │   Windows 11    │              │
│  │ (separate stack)│  │ (separate stack)│              │
│  └─────────────────┘  └─────────────────┘              │
└─────────────────────────────────────────────────────────┘
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in the project root with your specific values:

```bash
# NordVPN Configuration
VPN_SERVICE_PROVIDER=nordvpn
VPN_TYPE=openvpn
OPENVPN_USER=your_nordvpn_service_credentials_username
OPENVPN_PASSWORD=your_nordvpn_service_credentials_password
OPENVPN_PROTOCOL=udp
SERVER_HOSTNAMES=nl884.nordvpn.com
SERVER_COUNTRIES=Netherlands

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
JELLYFIN_PORT=8096
SONARR_PORT=8989
RADARR_PORT=7878
TRANSMISSION_PORT=9091
PROWLARR_PORT=9696
GLANCES_PORT=61208

# Transmission/Flood Authentication
USERNAME=your_username
PASSWORD=your_password

# Minecraft Configuration
MINECRAFT_BEDROCK_PORT=19132
MINECRAFT_SERVER_NAME=Your Server Name
MINECRAFT_GAMEMODE=creative
MINECRAFT_DIFFICULTY=peaceful
MINECRAFT_ALLOW_CHEATS=true
MINECRAFT_MAX_PLAYERS=10
MINECRAFT_LEVEL_NAME=Kids Town World
MINECRAFT_LEVEL_TYPE=FLAT

# DuckDNS Configuration (for external access)
DUCKDNS_SUBDOMAINS=your-subdomain
DUCKDNS_TOKEN=your-duckdns-token

# Watchtower Notifications (optional)
WATCHTOWER_NOTIFICATION_URL=
```

### DNS Configuration (Optional)

For clean `.river.local` domain names, you have two options:

#### Option 1: Local DNS Server (Pi-hole, AdGuard Home, etc.)

Add DNS records pointing all `*.river.local` domains to your server's IP address.

#### Option 2: /etc/hosts File

Add entries to `/etc/hosts` on each client device:

```
YOUR_SERVER_IP    jellyfin.river.local
YOUR_SERVER_IP    flood.river.local
YOUR_SERVER_IP    sonarr.river.local
YOUR_SERVER_IP    radarr.river.local
YOUR_SERVER_IP    prowlarr.river.local
YOUR_SERVER_IP    dashy.river.local
YOUR_SERVER_IP    glances.river.local
YOUR_SERVER_IP    traefik.river.local
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
   ./manage.sh start
   ```

3. **Check status**:
   ```bash
   ./manage.sh status
   ```

4. **Optional: Start Minecraft**:
   ```bash
   ./manage.sh start minecraft
   ```

5. **Optional: Start Windows VM**:
   ```bash
   ./manage.sh start windows
   ```

### Manual Docker Compose Method

If you prefer to use docker-compose directly:

1. **Initialize directories** (first time only):
   ```bash
   docker-compose -f docker-compose.init.yml up
   ```

2. **Start main services**:
   ```bash
   docker-compose up -d
   ```

3. **Start optional services**:
   ```bash
   # Minecraft
   docker-compose -f docker-compose.minecraft.yml up -d
   
   # Windows VM
   docker-compose -f docker-compose.windows.yml up -d
   ```

### Management Script Commands

The `manage.sh` script provides convenient commands:

```bash
./manage.sh start [service]     # Start services (main|minecraft|windows|all)
./manage.sh stop [service]      # Stop services
./manage.sh restart [service]   # Restart services
./manage.sh logs [service]      # View logs
./manage.sh status              # Show all container status
./manage.sh update [service]    # Update and restart services
./manage.sh init                # Initialize directories
./manage.sh help                # Show all commands
```

### First-Time Access

After starting services, wait 2-3 minutes for health checks, then access:

- **Dashboard**: http://dashy.river.local (or http://localhost:4000)
- **Media Server**: http://jellyfin.river.local (or http://localhost:8096)
- **Torrents**: http://flood.river.local (or http://localhost:3000)

## 📱 Initial Service Configuration

### 1. Flood (Torrent UI)

Access http://flood.river.local and configure:

- **Client Type**: Transmission
- **Hostname**: `gluetun`
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
3. Host: `gluetun`, Port: `9091`
4. Add root folder: `/tv`

### 4. Radarr (Movies)

1. Access http://radarr.river.local
2. Settings → Download Clients → Add Transmission
3. Host: `gluetun`, Port: `9091`
4. Add root folder: `/movies`

### 5. Jellyfin (Media Server)

1. Access http://jellyfin.river.local
2. Complete initial setup wizard
3. Add media libraries:
   - Movies: `/media/movies`
   - TV Shows: `/media/tv`
4. Enable hardware acceleration (Dashboard → Playback)

### 6. Minecraft Server

Access via Minecraft Bedrock Edition:
- **Server Address**: `YOUR_PUBLIC_IP:19132`
- **Or**: `river-minecraft.duckdns.org:19132`
- **Operators**: Configure in .env `MINECRAFT_OPS`

### 7. Windows 11 VM

- **Web Viewer**: http://localhost:8006
- **RDP**: Use any RDP client to connect to `localhost:3389`
- **First boot**: Takes 10-15 minutes for Windows installation

## 🔒 Security & Stability Features

### Security

- **VPN Protection**: All torrent traffic routed through NordVPN (Netherlands, UDP)
- **Network Isolation**: Transmission isolated within VPN network stack
- **Firewall Rules**: Gluetun restricts outbound traffic
- **User Isolation**: Services run with specified PUID/PGID
- **Health Checks**: All services monitored for proper operation
- **Conditional Dependencies**: Services start in correct order

### Stability Improvements

- **Modular Architecture**: Services split into logical stacks
- **Health-Based Dependencies**: Transmission waits for VPN to be healthy
- **Independent Services**: Minecraft and Windows can restart without affecting media server
- **Optimized Health Checks**: Reduced overhead, longer start periods
- **Proper Dependency Chain**: No circular dependencies or race conditions
- **Resource Management**: Windows VM only consumes resources when running

## 🔄 Automatic Updates & Maintenance

### Watchtower (Automatic Updates)

**Watchtower** keeps your containers automatically updated:

- **Schedule**: Daily at 4:00 AM
- **Rolling Restarts**: Updates one service at a time
- **Automatic Cleanup**: Removes old images
- **Notification Support**: Discord, Slack, email, etc.

Configure notifications in `.env`:

```bash
# Discord
WATCHTOWER_NOTIFICATION_URL=discord://webhook_id/webhook_token

# Email
WATCHTOWER_NOTIFICATION_URL=smtp://user:pass@host:port/?fromAddress=from@example.com&toAddresses=to@example.com
```

### Management Commands

```bash
# Using manage.sh (recommended)
./manage.sh start              # Start main services
./manage.sh stop all           # Stop everything
./manage.sh restart main       # Restart main services
./manage.sh logs               # View logs
./manage.sh status             # Check all containers
./manage.sh update all         # Pull updates and restart

# Direct docker-compose
docker-compose ps              # Check status
docker-compose logs -f         # Follow logs
docker-compose restart         # Restart services
docker-compose pull            # Pull updates
docker-compose up -d           # Apply updates
```

### Service-Specific Management

```bash
# Minecraft
./manage.sh start minecraft
./manage.sh stop minecraft
./manage.sh logs minecraft

# Windows VM
./manage.sh start windows
./manage.sh stop windows      # Graceful shutdown (2 min grace period)

# Main services only
./manage.sh restart main
```

## 🎬 Initial Setup Workflow

1. **Start services**: `docker-compose up -d`
2. **Configure Pi-hole DNS**: Run `pihole-dns-setup.sh` or manually add DNS records
3. **Setup Dashy Dashboard**: Access <http://dashy.river.local> and configure service tiles
4. **Configure Prowlarr**: Add torrent indexers at <http://prowlarr.river.local>
5. **Setup Sonarr**: Configure quality profiles and connect to Prowlarr at <http://sonarr.river.local>
6. **Setup Radarr**: Configure quality profiles and connect to Prowlarr at <http://radarr.river.local>
7. **Configure Transmission**: Set download directories and preferences at <http://transmission.river.local:9091/transmission/web/>
8. **Setup Jellyfin**: Add media libraries and configure transcoding at <http://jellyfin.river.local>

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
      - title: Jellyfin
        url: http://jellyfin.river.local
        icon: hl-jellyfin
      - title: Sonarr
        url: http://sonarr.river.local
        icon: hl-sonarr
      - title: Radarr
        url: http://radarr.river.local
        icon: hl-radarr
      - title: Prowlarr
        url: http://prowlarr.river.local
        icon: hl-prowlarr
        
  - name: Download & VPN
    items:
      - title: Transmission
        url: http://transmission.river.local:9091/transmission/web/
        icon: hl-transmission
        
  - name: System
    items:
      - title: Glances
        url: http://glances.river.local
        icon: hl-glances
      - title: Traefik
        url: http://traefik.river.local
        icon: hl-traefik
```

### Advanced Features

- **Status Indicators**: Enable health checks for real-time service status
- **Custom Widgets**: Add system info, weather, or other widgets
- **Themes**: Choose from multiple built-in themes or create custom ones
- **Mobile Support**: Responsive design works great on mobile devices

## 🎥 Hardware Acceleration (Jellyfin)

Jellyfin is configured for Intel QuickSync hardware acceleration:

- **Requirements**: Intel CPU with integrated graphics (6th gen or newer)
- **Devices**: `/dev/dri/renderD128` and `/dev/dri/card1`
- **Benefits**: 10x faster transcoding, lower CPU usage
- **Codecs**: Hardware H.264, H.265, VP9 encoding/decoding

**To enable:**

1. Access Jellyfin Dashboard → Playback → Transcoding
2. Hardware Acceleration: Select "Intel QuickSync (QSV)"
3. Enable hardware encoding options
4. Save and test with a transcode

## 🚨 Troubleshooting

### VPN Connection Issues

```bash
# Check VPN status
./manage.sh logs | grep -i gluetun

# Verify VPN connection
docker exec gluetun wget -qO- ifconfig.me
# Should show Netherlands IP: 193.142.200.22 or similar

# Check for UDP connection
docker-compose logs gluetun | grep -i udp
# Should show: "UDPv4 link remote"
```

**Common fixes:**
- Verify NordVPN credentials in `.env`
- Check `SERVER_HOSTNAMES=nl884.nordvpn.com`
- Ensure `OPENVPN_PROTOCOL=udp` is set

### Transmission/Flood Not Working

```bash
# Check if Transmission is accessible via Gluetun
docker exec gluetun wget -qO- http://localhost:9091

# Check Flood logs
./manage.sh logs | grep -i flood

# Verify Flood can reach Transmission
docker exec flood wget -qO- http://gluetun:9091
```

**Common fixes:**
- Ensure Gluetun is healthy before Transmission starts
- Verify credentials match in Flood and `.env`
- Hostname in Flood must be `gluetun`, not `localhost`

### Service Won't Start

```bash
# Check health status
./manage.sh status

# View specific service logs
docker-compose logs [service_name]

# Check dependencies
docker-compose ps
```

**Common fixes:**
- Wait for health checks (some services take 2-3 minutes)
- Check PUID/PGID permissions
- Ensure required directories exist (`./manage.sh init`)
- Verify `.env` file exists and is configured

### Permission Issues

```bash
# Check directory ownership
ls -la ${CONFIG_ROOT}/

# Fix permissions (replace 1000:1000 with your PUID:PGID)
sudo chown -R 1000:1000 ${CONFIG_ROOT}
sudo chown -R 1000:1000 ${DOWNLOADS_ROOT}
sudo chown -R 1000:1000 ${MEDIA_ROOT}

# Reinitialize directories
./manage.sh init
```

### Minecraft Connection Issues

```bash
# Check if server is running
./manage.sh status | grep minecraft

# View Minecraft logs
./manage.sh logs minecraft

# Check port is accessible
netstat -tulpn | grep 19132
```

**Common fixes:**
- Ensure UDP port 19132 is forwarded on router
- Check firewall allows UDP 19132
- Verify server is running: `./manage.sh status`
- Use Bedrock Edition (not Java Edition)

### Windows VM Issues

```bash
# Check VM status
./manage.sh logs windows

# Check resource usage
docker stats windows

# Verify KVM support
ls -l /dev/kvm
```

**Common fixes:**
- Ensure `/dev/kvm` exists (requires KVM support)
- Give VM 10-15 minutes for first boot
- Check system has enough RAM (8GB required for VM)
- Use graceful shutdown: `./manage.sh stop windows` (2 min grace period)

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

- **Modular Stacks**: Main services, Minecraft, and Windows are independent
- **No Circular Dependencies**: Init runs separately, not on every startup
- **Health-Based Startup**: Services wait for dependencies to be healthy
- **Resource Efficiency**: Optional services (Minecraft/Windows) only run when needed

### VPN Configuration

- **Protocol**: OpenVPN over UDP (faster than TCP)
- **Location**: Netherlands (nl884.nordvpn.com)
- **Kill Switch**: Built into Gluetun - no leaks if VPN drops
- **Network Isolation**: Transmission can only access internet through VPN

### Service Dependencies

```
Main Stack Dependencies:
  Gluetun (VPN) → Transmission → Flood
  Prowlarr → Sonarr, Radarr
  All services → traefik (for routing)
  
Independent Stacks:
  Minecraft (no dependencies)
  Windows VM (no dependencies)
  Init (run once, no dependencies)
```

### Resource Requirements

- **Main Stack**: 2GB RAM minimum, 4GB recommended
- **Minecraft**: 1GB RAM additional
- **Windows VM**: 8GB RAM additional (only when running)
- **Storage**: Depends on media library size
- **CPU**: Intel with QuickSync recommended for Jellyfin transcoding

### Backup Recommendations

Essential data to backup regularly:

```bash
# Application configurations
${CONFIG_ROOT}/*

# Environment variables
.env

# Docker Compose files
docker-compose*.yml
manage.sh

# Optional: Media library (if not using external storage)
${MEDIA_ROOT}/*
```

### Port Reference

| Service | Internal Port | External Port | Protocol |
|---------|--------------|---------------|----------|
| Traefik | 80 | 80 | HTTP |
| Traefik Dashboard | 8080 | 8080 | HTTP |
| Jellyfin | 8096 | 8096 | HTTP |
| Flood | 3000 | 3000 | HTTP |
| Transmission | 9091 | 9091 | HTTP |
| Sonarr | 8989 | 8989 | HTTP |
| Radarr | 7878 | 7878 | HTTP |
| Prowlarr | 9696 | 9696 | HTTP |
| Dashy | 4000 | 4000 | HTTP |
| Glances | 61208 | 61208 | HTTP |
| Minecraft | 19132 | 19132 | UDP |
| Windows Web | 8006 | 8006 | HTTP |
| Windows RDP | 3389 | 3389 | TCP/UDP |

## 🔧 Advanced Configuration

### Custom VPN Server

Edit `.env` to change VPN location:

```bash
# Use different Netherlands server
SERVER_HOSTNAMES=nl123.nordvpn.com

# Or use different country
SERVER_COUNTRIES=Germany
SERVER_HOSTNAMES=de456.nordvpn.com
```

### Minecraft World Customization

Edit `.env` for different world settings:

```bash
MINECRAFT_GAMEMODE=survival    # or creative, adventure
MINECRAFT_DIFFICULTY=hard      # or easy, normal, peaceful
MINECRAFT_LEVEL_TYPE=DEFAULT   # or FLAT, LEGACY, AMPLIFIED
MINECRAFT_LEVEL_SEED=12345     # specific world seed
```

### Windows VM Resources

Edit `docker-compose.windows.yml` to adjust resources:

```yaml
environment:
  RAM_SIZE: "16G"    # Increase RAM
  CPU_CORES: "6"     # More CPU cores
  DISK_SIZE: "256G"  # Larger disk
```

### Watchtower Scheduling

Edit `docker-compose.yml` to change update schedule:

```yaml
watchtower:
  command: --schedule "0 0 2 * * *"  # 2 AM instead of 4 AM
```

## 🤝 Getting Help

### Logs for Debugging

```bash
# All services
./manage.sh logs

# Specific service
docker-compose logs -f jellyfin

# Last 100 lines
docker-compose logs --tail=100

# Since specific time
docker-compose logs --since 30m
```

### Container Status

```bash
# Quick status
./manage.sh status

# Detailed info
docker-compose ps -a

# Resource usage
docker stats
```

### Health Checks

```bash
# See health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Detailed health info
docker inspect gluetun | grep -A 20 Health
```

## 📚 Additional Resources

- **Gluetun VPN**: <https://github.com/qdm12/gluetun>
- **Flood UI**: <https://github.com/jesec/flood>
- **Jellyfin Docs**: <https://jellyfin.org/docs/>
- **Sonarr Wiki**: <https://wiki.servarr.com/sonarr>
- **Radarr Wiki**: <https://wiki.servarr.com/radarr>
- **Prowlarr Wiki**: <https://wiki.servarr.com/prowlarr>
- **Traefik Docs**: <https://doc.traefik.io/traefik/>
- **Minecraft Bedrock**: <https://github.com/itzg/docker-minecraft-bedrock-server>

## 📄 License

This configuration is provided as-is for personal use. Ensure compliance with local laws regarding media downloading and VPN usage. Always respect copyright and licensing requirements.
