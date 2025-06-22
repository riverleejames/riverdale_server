# Riverdale Media Server

A complete media server stack with automated downloading, VPN protection, streaming capabilities, and network-wide access using Docker Compose, Traefik reverse proxy, and Pi-hole DNS.

## 🎯 Overview

This setup provides a full-featured media server with the following capabilities:

- **Secure torrenting** through VPN (Gluetun with multiple VPN providers)
- **Automated TV show management** with Sonarr
- **Automated movie management** with Radarr
- **Torrent indexer management** with Prowlarr
- **Media streaming** with Jellyfin (with hardware acceleration)
- **Torrent client** with Transmission (VPN-protected)
- **Reverse proxy** with Traefik for clean domain access
- **Network-wide DNS** with Pi-hole for device-wide domain resolution
- **System monitoring** with Glances
- **Service dashboard** with Dashy
- **Automatic updates** with Watchtower

## 🌐 Network Access

All services are accessible via clean domain names through Traefik reverse proxy and Pi-hole DNS:

### Via Traefik Reverse Proxy (Port 80)

| Service | Domain | Description |
|---------|--------|-------------|
| **Jellyfin** | `jellyfin.river.local` | Media streaming server |
| **Sonarr** | `sonarr.river.local` | TV show management |
| **Radarr** | `radarr.river.local` | Movie management |
| **Prowlarr** | `prowlarr.river.local` | Torrent indexer management |
| **Glances** | `glances.river.local` | System monitoring |
| **Dashy** | `dashy.river.local` | Service dashboard |
| **Traefik** | `traefik.river.local` | Reverse proxy dashboard |
| **Whoami** | `whoami.river.local` | Test service |

### Direct Port Access

| Service | URL | Port | Notes |
|---------|-----|------|-------|
| **Transmission** | `transmission.river.local:9091/transmission/web/` | 9091 | VPN-protected, requires port access |
| **Watchtower** | - | - | Background service, no web interface |

## 📋 Service Details

### Core Media Services

- **Jellyfin** (8096): Media streaming with Intel QuickSync hardware acceleration
- **Sonarr** (8989): Automated TV show downloading and management
- **Radarr** (7878): Automated movie downloading and management
- **Prowlarr** (9696): Torrent indexer management and integration

### Download & VPN

- **Gluetun**: VPN container providing secure tunnel for Transmission
- **Transmission** (9091): Torrent client running through VPN protection

### Infrastructure

- **Traefik** (80/8080): Reverse proxy for clean domain access
- **Dashy** (4000→8080): Customizable dashboard for all services
- **Glances** (61208): Real-time system monitoring
- **Watchtower**: Automatic container updates (4 AM daily)

## 🔧 Prerequisites

- Docker and Docker Compose installed
- VPN account credentials (supports multiple providers via Gluetun)
- **Pi-hole running on your network** (can be on a separate machine) for DNS resolution
- Sufficient storage space for media and downloads
- Intel CPU with QuickSync support (optional, for Jellyfin hardware transcoding)

## 📁 Directory Structure

```
riverdale_server/
├── docker-compose.yml           # Main service configuration
├── .env                        # Environment variables (create from .env.example)
├── README.md                   # This documentation
├── SERVICE_ACCESS_GUIDE.md     # Quick service access reference
├── pihole-dns-setup.sh         # Pi-hole DNS configuration script (run on Pi-hole machine)
└── data/
    └── config/                 # Application configurations
        ├── dashy/
        ├── jellyfin/
        ├── sonarr/
        ├── radarr/
        ├── prowlarr/
        ├── transmission/
        ├── gluetun/
        ├── traefik/
        └── watchtower/

External Storage Locations:
├── downloads/                  # Download staging area
│   ├── complete/
│   ├── incomplete/
│   └── watch/
└── media/                      # Final media storage
    ├── movies/
    └── tv/
```

## 🌐 Network Architecture

```
Internet
    ↓
Pi-hole DNS Server (separate machine)
(*.river.local → 192.168.1.37)
    ↓
Your Network Devices
    ↓
Traefik Reverse Proxy (Port 80) on 192.168.1.37
    ↓
┌─────────────────────────────────────────┐
│         Docker Network                  │
│        (riverdale_network)              │
│                                         │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │   Gluetun   │  │   Other Services │   │
│  │    (VPN)    │  │  (Jellyfin,     │   │
│  │      ├──────┼──│   Sonarr, etc.) │   │
│  │ Transmission│  │                 │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
```

## ⚙️ Configuration

### Environment Variables

Copy the `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Then edit `.env` with your specific values:

```bash
# VPN Configuration (Gluetun supports multiple providers)
VPN_SERVICE_PROVIDER=nordvpn  # or surfshark, expressvpn, cyberghost, etc.
VPN_TYPE=openvpn              # or wireguard
OPENVPN_USER=your_vpn_username
OPENVPN_PASSWORD=your_vpn_password
SERVER_COUNTRIES=Ireland      # or your preferred server location

# User/Group IDs (run 'id' command to get your values)
PUID=1000
PGID=1000

# Timezone
TZ=Europe/Dublin

# Storage Paths - Adjust these to your setup
CONFIG_ROOT=./data/config
DOWNLOADS_ROOT=/path/to/downloads
MEDIA_ROOT=/path/to/media

# Service Ports
JELLYFIN_PORT=8096
SONARR_PORT=8989
RADARR_PORT=7878
TRANSMISSION_PORT=9091
PROWLARR_PORT=9696
DASHY_PORT=4000
GLANCES_PORT=61208

# Transmission Authentication
USERNAME=your_username
PASSWORD=your_password

# Watchtower Configuration
# Optional: Set up notifications (Discord, Slack, email, etc.)
WATCHTOWER_NOTIFICATION_URL=
```

### Pi-hole DNS Configuration

**Important**: Pi-hole should be running on your network and handling DHCP/DNS for all devices. Since Pi-hole is hosted on a separate machine, you'll need to configure DNS records on that Pi-hole server.

#### Option 1: Automated Setup (Recommended)

1. **Transfer the setup script** to your Pi-hole server:

   ```bash
   scp pihole-dns-setup.sh user@pihole-server-ip:/home/user/
   ```

2. **Run the script on your Pi-hole server**:

   ```bash
   ssh user@pihole-server-ip
   sudo bash pihole-dns-setup.sh
   ```

#### Option 2: Manual Configuration

1. **Access Pi-hole Admin Interface** on your Pi-hole server
2. **Navigate to**: Local DNS → DNS Records
3. **Add DNS records** pointing to your Riverdale server (replace `192.168.1.37` with your server's IP):

   | Domain | IP Address | Service |
   |--------|------------|---------|
   | `jellyfin.river.local` | `192.168.1.37` | Media streaming |
   | `sonarr.river.local` | `192.168.1.37` | TV show management |
   | `radarr.river.local` | `192.168.1.37` | Movie management |
   | `prowlarr.river.local` | `192.168.1.37` | Indexer management |
   | `glances.river.local` | `192.168.1.37` | System monitoring |
   | `dashy.river.local` | `192.168.1.37` | Service dashboard |
   | `traefik.river.local` | `192.168.1.37` | Reverse proxy dashboard |
   | `whoami.river.local` | `192.168.1.37` | Test service |
   | `transmission.river.local` | `192.168.1.37` | Download client |

4. **Verify Pi-hole is being used** as DNS server by your devices:
   - Check router DHCP settings point to Pi-hole
   - Or manually configure devices to use Pi-hole IP as DNS server

#### Verification

Test DNS resolution from any device on your network:

```bash
nslookup jellyfin.river.local
# Should return 192.168.1.37
```

### Storage Requirements

Ensure you have adequate storage space:

- **Downloads**: Temporary storage for torrents (can be large)
- **Media**: Permanent storage for your media library
- **Config**: Application settings and databases (minimal space)

## 🚀 Getting Started

1. **Clone or download** this configuration to your server
2. **Create environment file**: Copy `.env.example` to `.env` and configure your specific values
3. **Configure storage paths** in `.env` and ensure directories exist with proper permissions
4. **Configure Pi-hole DNS** on your Pi-hole server using the included script or manual setup
5. **Start the stack**:

   ```bash
   docker-compose up -d
   ```

6. **Verify services** are running:

   ```bash
   docker-compose ps
   ```

7. **Test network access**: Try accessing `http://dashy.river.local` from any device on your network

## 📱 Access Applications

### Clean Domain Access (via Traefik + Pi-hole)

Once Pi-hole DNS is configured, access services using clean URLs:

- **Dashy Dashboard**: <http://dashy.river.local>
- **Jellyfin**: <http://jellyfin.river.local>
- **Sonarr**: <http://sonarr.river.local>
- **Radarr**: <http://radarr.river.local>
- **Prowlarr**: <http://prowlarr.river.local>
- **Glances**: <http://glances.river.local>
- **Traefik Dashboard**: <http://traefik.river.local>
- **Test Service**: <http://whoami.river.local>

### Direct Port Access (fallback)

- **Dashy Dashboard**: http://[server-ip]:4000
- **Jellyfin**: http://[server-ip]:8096
- **Sonarr**: http://[server-ip]:8989
- **Radarr**: http://[server-ip]:7878
- **Prowlarr**: http://[server-ip]:9696
- **Transmission**: http://[server-ip]:9091/transmission/web/
- **Glances**: http://[server-ip]:61208
- **Traefik Dashboard**: http://[server-ip]:8080

### Special Case: Transmission

Due to VPN network isolation, Transmission requires port-specific access:

- **With domain**: <http://transmission.river.local:9091/transmission/web/>
- **Direct IP**: http://[server-ip]:9091/transmission/web/

## 🔒 Security Features

- **VPN Protection**: All torrent traffic routed through Gluetun VPN container
- **Network Isolation**: Transmission isolated within VPN network stack
- **Firewall Rules**: Outbound traffic restricted to local subnets and VPN
- **User Isolation**: Services run with specified PUID/PGID for security
- **Reverse Proxy**: Traefik handles SSL termination and routing (HTTP currently, HTTPS can be added)
- **DNS Security**: Pi-hole provides ad-blocking and DNS filtering network-wide

## 🔄 Automatic Updates

**Watchtower** keeps your containers automatically updated:

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

## 🎥 Hardware Acceleration

Jellyfin is configured for Intel QuickSync hardware acceleration:

- Requires Intel CPU with integrated graphics (6th gen or newer recommended)
- Uses `/dev/dri/renderD128` and `/dev/dri/card1` devices
- Significantly improves transcoding performance and reduces CPU usage
- Supports hardware-accelerated H.264 and H.265 encoding/decoding

To verify hardware acceleration is working:

1. Access Jellyfin at <http://jellyfin.river.local>
2. Go to Dashboard → Playback → Transcoding
3. Enable "Intel QuickSync Video" options
4. Monitor transcoding performance in Dashboard → Activity

## 🔧 Maintenance

### Service Management

```bash
# View all service status
docker-compose ps

# View service logs
docker-compose logs [service_name]
docker-compose logs jellyfin
docker-compose logs transmission

# Restart specific service
docker-compose restart [service_name]

# Stop all services
docker-compose down

# Start all services
docker-compose up -d
```

### Updates

```bash
# Pull latest images
docker-compose pull

# Recreate containers with new images
docker-compose up -d

# Or let Watchtower handle updates automatically
```

### Backup Important Data

Essential directories to backup regularly:

- `data/config/` - Application configurations and databases
- `.env` - Environment variables and credentials
- `docker-compose.yml` - Service configuration
- Media library (if not using external storage)

### Network Testing

```bash
# Test DNS resolution
nslookup jellyfin.river.local

# Test service connectivity
curl -I http://jellyfin.river.local
curl -I http://transmission.river.local:9091/transmission/web/

# Check Traefik routing
curl -I http://traefik.river.local
```

## 🚨 Troubleshooting

### VPN Issues

```bash
# Check VPN container health
docker-compose ps gluetun

# View VPN logs
docker-compose logs gluetun

# Test VPN connectivity
docker exec gluetun wget -qO- ifconfig.me
```

**Common fixes:**

- Verify VPN credentials in `.env`
- Check VPN server location/availability
- Ensure VPN service provider is correctly specified

### Transmission Access Issues

```bash
# Check if Transmission is accessible
curl -I http://localhost:9091/transmission/web/

# Verify port mapping
docker port gluetun
```

**Common fixes:**

- Ensure Gluetun container is healthy
- Check `TRANSMISSION_PORT` environment variable
- Access via: `http://transmission.river.local:9091/transmission/web/`

### Traefik Routing Issues

```bash
# Check Traefik dashboard for registered services
curl http://traefik.river.local/api/http/routers

# View Traefik logs
docker-compose logs traefik
```

**Common fixes:**

- Ensure Pi-hole DNS is configured and working
- Verify domain resolution: `nslookup jellyfin.river.local`
- Check container labels in docker-compose.yml

### DNS Resolution Problems

```bash
# Test Pi-hole DNS from client device
nslookup jellyfin.river.local

# Test Pi-hole DNS directly (replace with your Pi-hole IP)
nslookup jellyfin.river.local 192.168.1.100

# Check if devices are using Pi-hole as DNS
cat /etc/resolv.conf  # Linux
# or check network settings on Windows/Mac
```

**Common fixes:**

- Transfer and run `pihole-dns-setup.sh` script on Pi-hole server
- Ensure Pi-hole server is accessible from your network
- Configure router DHCP to use Pi-hole as DNS server
- Manually set DNS on devices to Pi-hole IP address
- Verify Pi-hole is handling both DNS and DHCP properly

### Permission Issues

```bash
# Check directory ownership
ls -la data/config/

# Fix ownership (replace 1000:1000 with your PUID:PGID)
sudo chown -R 1000:1000 data/
```

**Common fixes:**

- Ensure PUID/PGID match your user: `id`
- Run init container: `docker-compose restart init-directories`

### Storage Issues

```bash
# Check disk space
df -h

# Verify mount points
mount | grep -E "(downloads|media)"
```

**Common fixes:**

- Ensure storage paths exist and are accessible
- Check permissions on storage directories
- Verify external drives are mounted correctly

### Container Health Issues

```bash
# Check container status
docker-compose ps

# View container resource usage
docker stats

# Check system resources
docker exec glances glances -t 1
```

### Service-Specific Issues

#### Jellyfin

- **No hardware acceleration**: Check Intel GPU drivers and device permissions
- **Transcoding failures**: Monitor Dashboard → Activity for errors
- **Network discovery not working**: Ensure `JELLYFIN_PublishedServerUrl` is set correctly

#### Sonarr/Radarr

- **Download client not found**: Ensure Prowlarr is configured and connected
- **File permissions**: Check PUID/PGID settings and directory ownership

#### Pi-hole (if using separate Pi-hole)

- **DNS not resolving**: Ensure Pi-hole is running and accessible on your network
- **Domain resolution failing**:

  ```bash
  # Test from Pi-hole server
  nslookup jellyfin.river.local
  
  # Test from client device
  nslookup jellyfin.river.local
  ```

- **Blocked queries**: Check Pi-hole query log for blocked domains
- **DHCP issues**: Ensure Pi-hole DHCP is properly configured and devices are getting Pi-hole as DNS server

## 📝 Notes

- **Initialization**: The `init-directories` container creates required directory structure on first run
- **VPN Dependency**: Transmission will not start without a working VPN connection
- **Network Architecture**: Services use Traefik reverse proxy for clean domain access
- **DNS Requirements**: Pi-hole DNS configuration required for domain resolution (Pi-hole can be on separate machine)
- **Resource Usage**: Consider CPU and RAM requirements for transcoding and multiple downloads
- **Docker Network**: All services communicate through the `riverdale_network` bridge network
- **Transmission Limitation**: Due to VPN network isolation, Transmission requires port-specific access (`transmission.river.local:9091`)
- **Hardware Acceleration**: Intel QuickSync support requires compatible CPU and proper device mapping
- **Pi-hole Setup**: The included `pihole-dns-setup.sh` script should be run on your Pi-hole server, not the Riverdale server

## 📚 Additional Resources

- **SERVICE_ACCESS_GUIDE.md**: Quick reference for all service URLs and access methods
- **pihole-dns-setup.sh**: Automated script for Pi-hole DNS configuration
- **Gluetun Documentation**: <https://github.com/qdm12/gluetun> for VPN provider setup
- **Traefik Documentation**: <https://doc.traefik.io/traefik/> for advanced reverse proxy configuration
- **Jellyfin Hardware Acceleration**: <https://jellyfin.org/docs/general/administration/hardware-acceleration/>

## 🤝 Contributing

Feel free to submit issues and enhancement requests! Some areas for improvement:

- HTTPS/SSL certificate automation with Let's Encrypt
- Additional VPN provider configurations
- Custom Traefik middleware for enhanced security
- Automated backup solutions
- Monitoring and alerting enhancements

## 📄 License

This configuration is provided as-is for personal use. Ensure compliance with local laws regarding media downloading and sharing. Always respect copyright and licensing requirements.

## 🌍 Internet Exposure (NEW!)

Want to share your media server with neighborhood kids? We've added comprehensive internet exposure capabilities!

### 🚀 Quick Setup

1. **Run the setup script:**

   ```bash
   ./scripts/setup-external-access.sh
   ```

2. **Configure your router** to forward ports 80 and 443 to your server

3. **Start with external access:**

   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.external.yml up -d
   ```

### 🔐 Security Features

- **SSL/TLS encryption** with automatic Let's Encrypt certificates
- **Authentication protection** for admin services
- **Kids-friendly dashboard** with appropriate content access
- **Rate limiting** and security headers
- **Comprehensive monitoring** and access logging

### 📚 Documentation

- **[Internet Exposure Guide](INTERNET_EXPOSURE_GUIDE.md)** - Complete setup instructions
- **[Security Guide](SECURITY_GUIDE.md)** - Essential security practices
- **[Kids Dashboard Config](config-examples/dashy-kids-config.yml)** - Child-friendly interface

### 🌐 External Access URLs

Once configured, kids can access via:

- **Main Dashboard**: `https://yourdomain.com`
- **Jellyfin Media**: `https://jellyfin.yourdomain.com`
- **Mobile Apps**: Available for iOS and Android
