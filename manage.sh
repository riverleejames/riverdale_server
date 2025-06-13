#!/bin/bash

# Riverdale Media Server Management Script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}Riverdale Media Server Management${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}start${NC}     - Start all services"
    echo -e "  ${GREEN}stop${NC}      - Stop all services"
    echo -e "  ${GREEN}restart${NC}   - Restart all services"
    echo -e "  ${GREEN}status${NC}    - Show service status"
    echo -e "  ${GREEN}logs${NC}      - Show logs for all services"
    echo -e "  ${GREEN}vpn-check${NC} - Check VPN connection"
    echo -e "  ${GREEN}update${NC}    - Update all containers"
    echo -e "  ${GREEN}cleanup${NC}   - Clean up unused Docker resources"
    echo ""
    echo "Service-specific commands:"
    echo -e "  ${YELLOW}logs <service>${NC} - Show logs for specific service"
    echo -e "  ${YELLOW}restart <service>${NC} - Restart specific service"
    echo ""
    echo "Services: gluetun, qbittorrent, jellyfin, sonarr, radarr, prowlarr"
}

case "$1" in
    start)
        echo -e "${BLUE}🚀 Starting Riverdale Media Server...${NC}"
        docker-compose up -d
        ;;
    stop)
        echo -e "${YELLOW}🛑 Stopping Riverdale Media Server...${NC}"
        docker-compose down
        ;;
    restart)
        echo -e "${BLUE}🔄 Restarting Riverdale Media Server...${NC}"
        docker-compose restart
        ;;
    status)
        echo -e "${BLUE}📊 Service Status:${NC}"
        docker-compose ps
        ;;
    logs)
        if [ -n "$2" ]; then
            echo -e "${BLUE}📋 Logs for $2:${NC}"
            docker-compose logs -f "$2"
        else
            echo -e "${BLUE}📋 All Logs:${NC}"
            docker-compose logs -f
        fi
        ;;
    vpn-check)
        echo -e "${BLUE}🔍 Checking VPN connection...${NC}"
        echo -n "Current IP: "
        docker-compose exec gluetun wget -qO- ifconfig.me
        echo ""
        ;;
    update)
        echo -e "${BLUE}⬆️  Updating containers...${NC}"
        docker-compose pull
        docker-compose up -d
        echo -e "${GREEN}✅ Update complete${NC}"
        ;;
    cleanup)
        echo -e "${BLUE}🧹 Cleaning up Docker resources...${NC}"
        docker system prune -f
        docker volume prune -f
        echo -e "${GREEN}✅ Cleanup complete${NC}"
        ;;
    restart)
        if [ -n "$2" ]; then
            echo -e "${BLUE}🔄 Restarting $2...${NC}"
            docker-compose restart "$2"
        else
            echo -e "${RED}❌ Please specify a service to restart${NC}"
            show_help
        fi
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
