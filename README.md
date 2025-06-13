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
| **Jellyfin** | 8096 | Media streaming server |
| **Sonarr** | 8989 | TV show management |
| **Radarr** | 7878 | Movie management |
| **Prowlarr** | 9696 | Torrent indexer management |
| **Transmission** | 9091 | Torrent client (via VPN) |

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
├── data/
│   ├── config/          # Application configurations
│   ├── downloads/       # Download staging area
│   └── media/           # Final media storage
│       ├── movies/
│       └── tv/
```

## ⚙️ Configuration

### Environment Variables

Copy the `.env.example` to `.env` and configure:

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
JELLYFIN_PORT=8096
SONARR_PORT=8989
RADARR_PORT=7878
TRANSMISSION_PORT=9091
PROWLARR_PORT=9696

# Transmission Authentication
USERNAME=your_username
PASSWORD=your_password
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

## 🎬 Initial Setup Workflow

1. **Start services**: `docker-compose up -d`
2. **Configure Prowlarr**: Add torrent indexers
3. **Setup Sonarr**: Configure quality profiles and connect to Prowlarr
4. **Setup Radarr**: Configure quality profiles and connect to Prowlarr
5. **Configure Transmission**: Set download directories and preferences
6. **Setup Jellyfin**: Add media libraries and configure transcoding

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
