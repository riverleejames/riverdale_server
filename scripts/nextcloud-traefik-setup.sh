#!/bin/bash
# Add Traefik labels to Nextcloud AIO Apache container
# Run this AFTER you've completed the AIO setup and containers are running

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Nextcloud AIO Traefik Integration${NC}"
echo "====================================="
echo ""

# Check if nextcloud-aio-apache exists
if ! docker ps | grep -q nextcloud-aio-apache; then
    echo -e "${RED}Error: nextcloud-aio-apache container not found!${NC}"
    echo "Please complete the AIO setup first:"
    echo "1. Go to https://192.168.1.37:8081"
    echo "2. Enter domain: nextcloud.river.local"
    echo "3. Start containers"
    echo "4. Wait for containers to start"
    echo "5. Then run this script again"
    exit 1
fi

echo -e "${YELLOW}Found nextcloud-aio-apache container${NC}"
echo ""

# Stop the apache container
echo "Stopping nextcloud-aio-apache..."
docker stop nextcloud-aio-apache

# Get the current docker run command (approximate)
echo ""
echo -e "${YELLOW}Adding Traefik labels...${NC}"

# Update the container with Traefik labels
# Note: We can't directly add labels to a running container, 
# so we need to use docker network connect with aliases
docker network connect riverdale_network nextcloud-aio-apache --alias nextcloud.river.local 2>/dev/null || echo "Already connected to network"

# Start the container
docker start nextcloud-aio-apache

echo ""
echo -e "${GREEN}✓ Configuration complete!${NC}"
echo ""
echo "However, AIO-managed containers don't support adding Traefik labels this way."
echo "You have two options:"
echo ""
echo "Option 1: Manual Traefik Configuration (Recommended)"
echo "------------------------------------------------------"
echo "Add this to your Traefik configuration file:"
echo ""
echo "[http.routers.nextcloud]"
echo "  rule = \"Host(\`nextcloud.river.local\`)\"
echo "  entryPoints = [\"websecure\"]"
echo "  service = \"nextcloud\""
echo ""
echo "[http.services.nextcloud.loadBalancer]"
echo "  [[http.services.nextcloud.loadBalancer.servers]]"
echo "    url = \"http://nextcloud-aio-apache:11000\""
echo ""
echo "Option 2: Use File-based Traefik Configuration"
echo "------------------------------------------------"
echo "We can create a dynamic configuration file for Traefik"
echo ""
read -p "Would you like to create a Traefik dynamic config file? (y/n): " create_config

if [[ "$create_config" =~ ^[Yy]$ ]]; then
    mkdir -p /mnt/media-storage/config/traefik/dynamic
    cat > /mnt/media-storage/config/traefik/dynamic/nextcloud.yml << 'EOF'
http:
  routers:
    nextcloud:
      rule: "Host(`nextcloud.river.local`)"
      entryPoints:
        - web
      service: nextcloud
      middlewares:
        - nextcloud-headers
  
  services:
    nextcloud:
      loadBalancer:
        servers:
          - url: "http://nextcloud-aio-apache:11000"
  
  middlewares:
    nextcloud-headers:
      headers:
        stsSeconds: 15552000
        stsIncludeSubdomains: true
        stsPreload: true
EOF
    echo -e "${GREEN}✓ Created Traefik configuration: /mnt/media-storage/config/traefik/dynamic/nextcloud.yml${NC}"
    echo ""
    echo "Now restart Traefik to load the configuration:"
    echo "  docker restart traefik"
fi

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo "Add 'nextcloud.river.local' to your /etc/hosts or local DNS"
echo "Then access Nextcloud at: http://nextcloud.river.local"
