# Riverdale Media Server

A complete media server stack with automated downloading, VPN protection, and streaming capabilities using Docker Compose.

## 🎯 Overview

This setup provides a full-featured media server with the following capabilities:
- **Secure torrenting** through VPN (NordVPN)
- **Automated TV show management** with Sonarr
- **Automated movie management** with Radarr
- **Torrent indexer management** with Prowlarr
- **Media streaming** with Jellyfin
- **Torrent client** with Transmission

## 📋 Services

| Service | Port | Description |
|---------|------|-------------|
| **Homarr** | 7575 | Dashboard for all services |
| **Jellyfin** | 8096 | Media streaming server |
| **Sonarr** | 8989 | TV show management |
| **Radarr** | 7878 | Movie management |
| **Prowlarr** | 9696 | Torrent indexer management |
| **Transmission** | 9091 | Torrent client (via VPN) |
| **Watchtower** | - | Automatic container updates |

## 🔧 Prerequisites

- Docker and Docker Compose installed
- NordVPN account credentials
- Sufficient storage space for media and downloads
- Hardware with Intel QuickSync support (for Jellyfin transcoding)

## 📁 Directory Structure

```
riverdale_server/
├── docker-compose.yml
├── .env
└── data/
    └── config/          # Application configurations only
        ├── homarr/
        ├── jellyfin/
        ├── sonarr/
        ├── radarr/
        ├── prowlarr/
        ├── transmission/
        ├── gluetun/
        └── watchtower/

/mnt/media-storage/          # Actual storage location (external mount)
├── downloads/               # Download staging area
│   ├── complete/
│   ├── incomplete/
│   └── watch/
└── media/                   # Final media storage
    ├── movies/
    └── tv/
```

## ⚙️ Configuration

### Environment Variables

Copy the `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Then edit `.env` with your specific values:

```bash
# VPN Configuration
VPN_SERVICE_PROVIDER=nordvpn
VPN_TYPE=openvpn
OPENVPN_USER=your_nordvpn_username
OPENVPN_PASSWORD=your_nordvpn_password
SERVER_COUNTRIES=Ireland

# User/Group IDs (run 'id' command to get your values)
PUID=1000
PGID=1000

# Timezone
TZ=Europe/Dublin

# Storage Paths
DATA_ROOT=/home/river/riverdale_server/data
CONFIG_ROOT=/home/river/riverdale_server/data/config
DOWNLOADS_ROOT=/mnt/media-storage/downloads
MEDIA_ROOT=/mnt/media-storage/media

# Service Ports
HOMARR_PORT=7575
JELLYFIN_PORT=8096
SONARR_PORT=8989
RADARR_PORT=7878
TRANSMISSION_PORT=9091
PROWLARR_PORT=9696

# Transmission Authentication
USERNAME=your_username
PASSWORD=your_password

# Homarr Configuration
HOMARR_SECRET_KEY=your_64_character_hex_string

# Watchtower Configuration
# Optional: Set up notifications (Discord, Slack, email, etc.)
# Example for Discord: discord://webhook_id/webhook_token
# Example for email: smtp://username:password@host:port/?fromAddress=from@example.com&toAddresses=to@example.com
WATCHTOWER_NOTIFICATION_URL=
```

### Storage Requirements

Ensure you have adequate storage space:
- **Downloads**: Temporary storage for torrents (can be large)
- **Media**: Permanent storage for your media library
- **Config**: Application settings and databases (minimal space)

## 🚀 Getting Started

1. **Clone or download** this configuration to your server
2. **Configure environment variables** in `.env`
3. **Ensure storage paths exist** and have proper permissions
4. **Start the stack**:
   ```bash
   docker-compose up -d
   ```

## 📱 Access Applications

Once running, access your services at:
- **Homarr Dashboard**: http://localhost:7575
- **Jellyfin**: http://localhost:8096
- **Sonarr**: http://localhost:8989
- **Radarr**: http://localhost:7878
- **Prowlarr**: http://localhost:9696
- **Transmission**: http://localhost:9091

## 🔒 Security Features

- **VPN Protection**: All torrent traffic routed through NordVPN
- **Network Isolation**: Transmission only accessible through VPN container
- **Firewall Rules**: Outbound traffic restricted to local subnets
- **User Isolation**: Services run with specified PUID/PGID

## 🔄 Automatic Updates

**Watchtower** is included to automatically keep your containers up to date:

- **Scheduled Updates**: Runs daily at 4:00 AM
- **Automatic Cleanup**: Removes old images after updates
- **Notification Support**: Configure Discord, Slack, email, or other notifications
- **Safe Updates**: Only updates containers that are running
- **Rollback Capability**: Docker retains previous images for manual rollback if needed

### Watchtower Configuration

To enable notifications, set the `WATCHTOWER_NOTIFICATION_URL` in your `.env` file:

**Discord Webhook:**
```bash
WATCHTOWER_NOTIFICATION_URL=discord://webhook_id/webhook_token
```

**Email Notifications:**
```bash
WATCHTOWER_NOTIFICATION_URL=smtp://username:password@host:port/?fromAddress=from@example.com&toAddresses=to@example.com
```

**Slack Webhook:**
```bash
WATCHTOWER_NOTIFICATION_URL=slack://webhook_url
```

To change the update schedule, modify the `WATCHTOWER_SCHEDULE` environment variable in `docker-compose.yml`. The current schedule `0 0 4 * * *` runs daily at 4:00 AM.

## 🎬 Initial Setup Workflow

1. **Start services**: `docker-compose up -d`
2. **Setup Homarr Dashboard**: Configure your dashboard with service tiles
3. **Configure Prowlarr**: Add torrent indexers
4. **Setup Sonarr**: Configure quality profiles and connect to Prowlarr
5. **Setup Radarr**: Configure quality profiles and connect to Prowlarr
6. **Configure Transmission**: Set download directories and preferences
7. **Setup Jellyfin**: Add media libraries and configure transcoding

## 🏠 Homarr Dashboard Configuration

**Homarr** provides a beautiful dashboard to manage all your services in one place. After starting the services:

1. **Access Homarr**: Navigate to http://localhost:7575
2. **Add Service Tiles**: Use the built-in service discovery or manually add:
   - **Jellyfin**: `http://jellyfin:8096` (internal) or `http://localhost:8096` (external)
   - **Sonarr**: `http://sonarr:8989` (internal) or `http://localhost:8989` (external)
   - **Radarr**: `http://radarr:7878` (internal) or `http://localhost:7878` (external)
   - **Prowlarr**: `http://prowlarr:9696` (internal) or `http://localhost:9696` (external)
   - **Transmission**: `http://gluetun:9091` (internal) or `http://localhost:9091` (external)

3. **Configure Integrations**: Enable Docker integration for container monitoring
4. **Customize Layout**: Arrange tiles, add widgets, and personalize your dashboard

**Pro Tips:**
- Use internal hostnames (e.g., `jellyfin:8096`) for better performance within the Docker network
- Enable Docker integration to see container status and resource usage
- Add custom tiles for other services or bookmarks
- Use the mobile-friendly interface for remote access

## 📊 Hardware Acceleration

Jellyfin is configured for Intel QuickSync hardware acceleration:
- Requires Intel CPU with integrated graphics
- Uses `/dev/dri/renderD128` and `/dev/dri/card1` devices
- Significantly improves transcoding performance

## 🔧 Maintenance

### Logs
View service logs:
```bash
docker-compose logs [service_name]
```

### Updates
Update all services:
```bash
docker-compose pull
docker-compose up -d
```

### Backup
Important directories to backup:
- `data/config/` - Application configurations and databases
- `.env` - Environment variables

## 🚨 Troubleshooting

### VPN Issues
- Check NordVPN credentials in `.env`
- Verify VPN container health: `docker-compose ps gluetun`
- Check logs: `docker-compose logs gluetun`

### Permission Issues
- Ensure PUID/PGID match your user: `id`
- Check directory ownership: `ls -la data/`
- Restart init container: `docker-compose restart init-directories`

### Storage Issues
- Verify mount points exist and are accessible
- Check disk space: `df -h`
- Ensure proper permissions on storage directories

## 📝 Notes

- **Initialization**: The `init-directories` container creates required directory structure on first run
- **VPN Dependency**: Transmission will not start without a working VPN connection
- **Resource Usage**: Consider CPU and RAM requirements for transcoding and multiple downloads
- **Network**: All services use the `riverdale_network` Docker network

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This configuration is provided as-is for personal use. Ensure compliance with local laws regarding media downloading and sharing.
