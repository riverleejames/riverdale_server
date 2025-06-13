#!/bin/bash

# Riverdale Media Server Setup Script
echo "🎬 Setting up Riverdale Media Server..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker and Docker Compose are installed${NC}"

# Create directory structure
echo -e "${BLUE}📁 Creating directory structure...${NC}"
mkdir -p data/config/{jellyfin,sonarr,radarr,prowlarr,qbittorrent,gluetun}
mkdir -p data/downloads/{complete,incomplete}
mkdir -p data/media/{movies,tv}

# Set permissions for new directories only (skip existing files owned by Docker)
echo -e "${BLUE}🔐 Setting permissions for new directories...${NC}"
find data/ -type d -exec chmod 755 {} \; 2>/dev/null || true
find data/ -type d -exec chown $(id -u):$(id -g) {} \; 2>/dev/null || true

# Check if .env file has been configured
if grep -q "your_nordvpn_email" .env; then
    echo -e "${YELLOW}⚠️  Please configure your .env file with your NordVPN credentials${NC}"
    echo -e "${YELLOW}   Edit .env and replace:${NC}"
    echo -e "${YELLOW}   - your_nordvpn_email${NC}"
    echo -e "${YELLOW}   - your_nordvpn_password${NC}"
    echo -e "${YELLOW}   Then run this script again.${NC}"
    exit 1
fi

# Display current user/group info
echo -e "${BLUE}👤 Current user info:${NC}"
echo "PUID: $(id -u)"
echo "PGID: $(id -g)"

# Check if PUID/PGID in .env matches current user
ENV_PUID=$(grep "PUID=" .env | cut -d'=' -f2)
ENV_PGID=$(grep "PGID=" .env | cut -d'=' -f2)

if [ "$ENV_PUID" != "$(id -u)" ] || [ "$ENV_PGID" != "$(id -g)" ]; then
    echo -e "${YELLOW}⚠️  PUID/PGID in .env doesn't match current user${NC}"
    echo -e "${YELLOW}   Updating .env file...${NC}"
    sed -i "s/PUID=.*/PUID=$(id -u)/" .env
    sed -i "s/PGID=.*/PGID=$(id -g)/" .env
fi

echo -e "${GREEN}✅ Directory structure and permissions set up${NC}"

# Clean up any corrupted containers
echo -e "${BLUE}🧹 Cleaning up any corrupted containers...${NC}"
docker-compose down --remove-orphans 2>/dev/null || true

# Start the services
echo -e "${BLUE}🚀 Starting services...${NC}"
if ! docker-compose up -d; then
    echo -e "${RED}❌ Failed to start services. Let's try to fix this...${NC}"
    echo -e "${YELLOW}🔧 Removing corrupted containers and trying again...${NC}"
    docker-compose down --volumes --remove-orphans
    docker system prune -f
    docker-compose up -d
fi

# Wait a moment for services to start
echo -e "${BLUE}⏳ Waiting for services to start...${NC}"
sleep 10

# Check service status
echo -e "${BLUE}📊 Service status:${NC}"
docker-compose ps

# Display access information
echo -e "${GREEN}🎉 Setup complete! Access your services at:${NC}"
echo -e "${GREEN}  • Jellyfin:    http://localhost:8096${NC}"
echo -e "${GREEN}  • Sonarr:      http://localhost:8989${NC}"
echo -e "${GREEN}  • Radarr:      http://localhost:7878${NC}"
echo -e "${GREEN}  • Prowlarr:    http://localhost:9696${NC}"
echo -e "${GREEN}  • qBittorrent: http://localhost:8080${NC}"

echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "${YELLOW}  1. Configure qBittorrent (default: admin/adminadmin)${NC}"
echo -e "${YELLOW}  2. Set up Prowlarr with your preferred indexers${NC}"
echo -e "${YELLOW}  3. Set up Sonarr and Radarr with qBittorrent as download client${NC}"
echo -e "${YELLOW}  4. Connect Sonarr and Radarr to Prowlarr for automatic indexer sync${NC}"
echo -e "${YELLOW}  5. Add your media libraries in Jellyfin${NC}"

echo -e "${BLUE}💡 Check VPN status with: docker-compose exec gluetun wget -qO- ifconfig.me${NC}"
