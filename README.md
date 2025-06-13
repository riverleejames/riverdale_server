# Riverdale Media Server

A complete media server setup using Docker Compose with:
- **Jellyfin** - Media server for streaming movies and TV shows
- **Sonarr** - TV show collection manager
- **Radarr** - Movie collection manager  
- **Prowlarr** - Indexer manager for Sonarr and Radarr
- **qBittorrent** - Torrent client
- **Gluetun** - VPN container (NordVPN) for secure torrenting

## Prerequisites

1. Docker and Docker Compose installed
2. NordVPN subscription
3. Proper user permissions set up

## Setup Instructions

### 1. Configure Environment Variables

Edit the `.env` file and update the following:

```bash
# Replace with your actual NordVPN credentials
OPENVPN_USER=your_nordvpn_email
OPENVPN_PASSWORD=your_nordvpn_password

# Update timezone if needed
TZ=America/New_York

# Get your user/group IDs
id
# Update PUID and PGID with your actual values
```

### 2. Set Directory Permissions

```bash
# Make sure all directories exist and have correct permissions
sudo chown -R $USER:$USER data/
chmod -R 755 data/
```

### 3. Start the Stack

```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f

# Check specific service logs
docker-compose logs gluetun
docker-compose logs qbittorrent
```

## Access Points

Once running, access your services at:

- **Jellyfin**: http://localhost:8096
- **Sonarr**: http://localhost:8989  
- **Radarr**: http://localhost:7878
- **Prowlarr**: http://localhost:9696
- **qBittorrent**: http://localhost:8080

## Configuration

### qBittorrent Setup
1. Default login: `admin` / `adminadmin`
2. Change default password immediately
3. Set download path to `/downloads`
4. Configure categories for movies/tv

### Sonarr Setup
1. Add download client (qBittorrent at `gluetun:8080`)
2. Add root folder `/tv`
3. Configure indexers for content discovery

### Radarr Setup  
1. Add download client (qBittorrent at `gluetun:8080`)
2. Add root folder `/movies`
3. Configure indexers for content discovery

### Prowlarr Setup
1. Complete initial setup wizard
2. Add indexers (torrent sites, usenet providers)
3. Connect to applications:
   - Add Sonarr: http://sonarr:8989
   - Add Radarr: http://radarr:7878
4. Prowlarr will automatically sync indexers to both apps

### Jellyfin Setup
1. Add media libraries:
   - Movies: `/media/movies`
   - TV Shows: `/media/tv`
2. Configure transcoding settings

## Security Notes

- All torrent traffic goes through VPN (Gluetun)
- Firewall rules prevent traffic leaks
- Sensitive config files are gitignored
- Change default passwords immediately

## Troubleshooting

### VPN Issues
```bash
# Check VPN connection
docker-compose exec gluetun wget -qO- ifconfig.me

# Restart VPN if needed
docker-compose restart gluetun
```

### Permission Issues
```bash
# Fix permissions
sudo chown -R $(id -u):$(id -g) data/
```

### Container Issues
```bash
# View all container status
docker-compose ps

# Restart specific service
docker-compose restart <service_name>
```
