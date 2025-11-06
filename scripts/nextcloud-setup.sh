#!/bin/bash
# Nextcloud AIO Setup Script
# This script helps you set up Nextcloud All-in-One

set -e

# Get script directory and change to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Nextcloud AIO Setup Script${NC}"
echo "================================"
echo ""

# Check if docker-compose is available
if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: docker-compose is not installed${NC}"
    exit 1
fi

# Determine docker compose command
if command -v docker compose &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Warning: .env file not found${NC}"
    echo "Please create .env from .env.example and configure Nextcloud settings"
    echo ""
    read -p "Would you like to continue anyway? (y/n): " continue_setup
    if [[ ! $continue_setup =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Start the Nextcloud AIO mastercontainer
echo -e "${YELLOW}Starting Nextcloud AIO mastercontainer...${NC}"
$DOCKER_COMPOSE -f docker-compose.nextcloud.yml up -d

echo ""
echo -e "${GREEN}Nextcloud AIO mastercontainer started!${NC}"
echo ""

# Wait a moment for the container to start
sleep 5

# Get the initial admin password
echo -e "${YELLOW}Retrieving initial admin password...${NC}"
ADMIN_PASSWORD=$(docker logs nextcloud-aio-mastercontainer 2>&1 | grep -oP '(?<=Initial password: ).*' | tail -1)

if [ -n "$ADMIN_PASSWORD" ]; then
    echo -e "${GREEN}Initial Admin Password: ${BLUE}$ADMIN_PASSWORD${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: Save this password! You'll need it for the initial setup.${NC}"
    echo ""
else
    echo -e "${YELLOW}Could not retrieve password automatically. Check logs with:${NC}"
    echo "docker logs nextcloud-aio-mastercontainer 2>&1 | grep 'Initial password'"
    echo ""
fi

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}Setup Instructions:${NC}"
echo "===================="
echo ""
echo "1. Open your browser and navigate to:"
echo -e "   ${BLUE}https://${SERVER_IP}:8081${NC}"
echo ""
echo "2. You'll see a security warning (self-signed certificate). Accept it."
echo ""
echo "3. Enter the initial admin password shown above"
echo ""
echo "4. Configure your Nextcloud settings:"
echo "   - Set your domain or IP address"
echo "   - Choose which containers to enable (Office, Talk, etc.)"
echo "   - Configure timezone and other settings"
echo ""
echo "5. After setup, access Nextcloud at:"
echo -e "   ${BLUE}https://${SERVER_IP}:11000${NC}"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "----------------"
echo "• Nextcloud AIO uses HTTPS with self-signed certificates by default"
echo "• For production use, configure a proper domain and SSL certificate"
echo "• The mastercontainer manages all other Nextcloud containers automatically"
echo "• All data is stored in the 'nextcloud_aio_mastercontainer' Docker volume"
echo ""
echo -e "${YELLOW}Optional Data Directory:${NC}"
echo "If you want to use a custom data directory instead of Docker volumes:"
echo "1. Stop the container: $DOCKER_COMPOSE -f docker-compose.nextcloud.yml down"
echo "2. Edit .env and set NEXTCLOUD_DATADIR=/mnt/media-storage/nextcloud-data"
echo "3. Create the directory: sudo mkdir -p /mnt/media-storage/nextcloud-data"
echo "4. Set permissions: sudo chown -R 33:0 /mnt/media-storage/nextcloud-data"
echo "5. Start again: $DOCKER_COMPOSE -f docker-compose.nextcloud.yml up -d"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "-----------------------------------"
echo "View mastercontainer logs:"
echo "  docker logs -f nextcloud-aio-mastercontainer"
echo ""
echo "View all Nextcloud containers:"
echo "  docker ps | grep nextcloud"
echo ""
echo "Stop Nextcloud:"
echo "  $DOCKER_COMPOSE -f docker-compose.nextcloud.yml down"
echo ""
echo "Restart Nextcloud:"
echo "  $DOCKER_COMPOSE -f docker-compose.nextcloud.yml restart"
echo ""
echo "Backup Nextcloud:"
echo "  Use the built-in backup feature in the AIO interface at https://${SERVER_IP}:8080"
echo ""
echo -e "${GREEN}Setup complete! Access the admin panel at https://${SERVER_IP}:8080${NC}"
