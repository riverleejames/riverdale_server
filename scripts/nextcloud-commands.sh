#!/bin/bash
# Nextcloud AIO Quick Commands

# Start Nextcloud
start_nextcloud() {
    docker compose -f docker-compose.nextcloud.yml up -d
    echo "Nextcloud AIO started"
}

# Stop Nextcloud
stop_nextcloud() {
    docker compose -f docker-compose.nextcloud.yml down
    echo "Nextcloud AIO stopped"
}

# Restart Nextcloud
restart_nextcloud() {
    docker compose -f docker-compose.nextcloud.yml restart
    echo "Nextcloud AIO restarted"
}

# View mastercontainer logs
logs_nextcloud() {
    docker logs -f nextcloud-aio-mastercontainer
}

# View Nextcloud app logs
logs_nextcloud_app() {
    docker logs -f nextcloud-aio-nextcloud
}

# List all Nextcloud containers
list_nextcloud() {
    docker ps | grep nextcloud
}

# Get admin password
get_password() {
    docker logs nextcloud-aio-mastercontainer 2>&1 | grep "Initial password" | tail -1
}

# Show admin URL
show_admin() {
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "Admin interface: https://${SERVER_IP}:8080"
    echo "Nextcloud web:   https://${SERVER_IP}:8443"
}

# Update Nextcloud
update_nextcloud() {
    docker compose -f docker-compose.nextcloud.yml pull
    docker compose -f docker-compose.nextcloud.yml up -d
    echo "Nextcloud AIO updated"
}

# Show help
show_help() {
    echo "Nextcloud AIO Management Commands"
    echo "=================================="
    echo ""
    echo "Usage: source scripts/nextcloud-commands.sh && <command>"
    echo ""
    echo "Available commands:"
    echo "  start_nextcloud      - Start Nextcloud AIO"
    echo "  stop_nextcloud       - Stop Nextcloud AIO"
    echo "  restart_nextcloud    - Restart Nextcloud AIO"
    echo "  logs_nextcloud       - View mastercontainer logs"
    echo "  logs_nextcloud_app   - View Nextcloud application logs"
    echo "  list_nextcloud       - List all Nextcloud containers"
    echo "  get_password         - Show initial admin password"
    echo "  show_admin           - Show admin and web interface URLs"
    echo "  update_nextcloud     - Update Nextcloud AIO"
    echo "  show_help            - Show this help message"
    echo ""
    echo "Example:"
    echo "  source scripts/nextcloud-commands.sh && start_nextcloud"
}

# If script is sourced, show help
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly"
    echo "Usage: source scripts/nextcloud-commands.sh && <command>"
    show_help
fi
