#!/bin/bash
# GitLab Runner Configuration Helper
# This script helps you view and edit the runner configuration

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

CONFIG_FILE="${CONFIG_ROOT}/gitlab-runner/config.toml"

echo -e "${GREEN}GitLab Runner Configuration Helper${NC}"
echo "===================================="
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Warning: Configuration file not found at:${NC}"
    echo "$CONFIG_FILE"
    echo ""
    echo "The config.toml file is created when you register a runner."
    echo "Run: docker exec -it gitlab-runner gitlab-runner register"
    exit 1
fi

echo -e "${YELLOW}Configuration file location:${NC}"
echo "$CONFIG_FILE"
echo ""

# Show current concurrent setting
echo -e "${YELLOW}Current concurrent jobs setting:${NC}"
grep "^concurrent" "$CONFIG_FILE" || echo "Not set (default: 1)"
echo ""

# Provide options
echo "What would you like to do?"
echo "1. View full configuration"
echo "2. Update concurrent jobs limit"
echo "3. Edit configuration manually"
echo "4. Exit"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}Current Configuration:${NC}"
        cat "$CONFIG_FILE"
        ;;
    2)
        read -p "Enter number of concurrent jobs (e.g., 4): " concurrent
        if [[ $concurrent =~ ^[0-9]+$ ]]; then
            # Backup config
            cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
            # Update concurrent value
            sed -i "s/^concurrent = .*/concurrent = $concurrent/" "$CONFIG_FILE"
            echo -e "${GREEN}✓ Updated concurrent jobs to: $concurrent${NC}"
            echo ""
            echo -e "${YELLOW}Restarting runner to apply changes...${NC}"
            docker compose -f docker-compose.gitlab-runner.yml restart
            echo -e "${GREEN}✓ Runner restarted${NC}"
        else
            echo -e "${RED}Error: Please enter a valid number${NC}"
        fi
        ;;
    3)
        echo ""
        echo -e "${YELLOW}Opening configuration in nano...${NC}"
        echo "Press Ctrl+X to exit, Y to save changes"
        echo ""
        read -p "Press Enter to continue..."
        nano "$CONFIG_FILE"
        echo ""
        read -p "Restart runner to apply changes? (y/n): " restart
        if [[ $restart =~ ^[Yy]$ ]]; then
            docker compose -f docker-compose.gitlab-runner.yml restart
            echo -e "${GREEN}✓ Runner restarted${NC}"
        fi
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC}"
