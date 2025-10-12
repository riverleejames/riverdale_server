#!/bin/bash
# Riverdale Server Management Script
# Manages multiple docker-compose files easily

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Show usage
show_usage() {
    cat << EOF
Riverdale Server Management Script

Usage: ./manage.sh [command] [service]

Commands:
  start [service]     - Start services
  stop [service]      - Stop services
  restart [service]   - Restart services
  logs [service]      - View logs
  status              - Show status of all services
  update [service]    - Update and restart services
  init                - Initialize directories (run once)
  
Services:
  main                - Main media server stack (default)
  minecraft           - Minecraft Bedrock server
  windows             - Windows 11 VM
  all                 - All services

Examples:
  ./manage.sh start               # Start main services
  ./manage.sh start minecraft     # Start Minecraft
  ./manage.sh stop all            # Stop everything
  ./manage.sh logs main           # View main service logs
  ./manage.sh status              # Check status
  ./manage.sh init                # Initialize directories

EOF
}

# Initialize directories
init_directories() {
    print_header "Initializing Directories"
    docker-compose -f docker-compose.init.yml up
    print_success "Directory initialization complete"
}

# Start services
start_service() {
    case $1 in
        main|"")
            print_header "Starting Main Services"
            docker-compose up -d
            print_success "Main services started"
            ;;
        minecraft)
            print_header "Starting Minecraft Server"
            docker-compose -f docker-compose.minecraft.yml up -d
            print_success "Minecraft server started"
            ;;
        windows)
            print_header "Starting Windows VM"
            docker-compose -f docker-compose.windows.yml up -d
            print_success "Windows VM started"
            ;;
        all)
            print_header "Starting All Services"
            docker-compose up -d
            docker-compose -f docker-compose.minecraft.yml up -d
            docker-compose -f docker-compose.windows.yml up -d
            print_success "All services started"
            ;;
        *)
            print_error "Unknown service: $1"
            exit 1
            ;;
    esac
}

# Stop services
stop_service() {
    case $1 in
        main|"")
            print_header "Stopping Main Services"
            docker-compose down
            print_success "Main services stopped"
            ;;
        minecraft)
            print_header "Stopping Minecraft Server"
            docker-compose -f docker-compose.minecraft.yml down
            print_success "Minecraft server stopped"
            ;;
        windows)
            print_header "Stopping Windows VM"
            print_warning "Shutting down Windows VM (2 minute grace period)..."
            docker-compose -f docker-compose.windows.yml down
            print_success "Windows VM stopped"
            ;;
        all)
            print_header "Stopping All Services"
            docker-compose down
            docker-compose -f docker-compose.minecraft.yml down
            docker-compose -f docker-compose.windows.yml down
            print_success "All services stopped"
            ;;
        *)
            print_error "Unknown service: $1"
            exit 1
            ;;
    esac
}

# Restart services
restart_service() {
    case $1 in
        main|"")
            print_header "Restarting Main Services"
            docker-compose restart
            print_success "Main services restarted"
            ;;
        minecraft)
            print_header "Restarting Minecraft Server"
            docker-compose -f docker-compose.minecraft.yml restart
            print_success "Minecraft server restarted"
            ;;
        windows)
            print_header "Restarting Windows VM"
            docker-compose -f docker-compose.windows.yml restart
            print_success "Windows VM restarted"
            ;;
        all)
            print_header "Restarting All Services"
            docker-compose restart
            docker-compose -f docker-compose.minecraft.yml restart
            docker-compose -f docker-compose.windows.yml restart
            print_success "All services restarted"
            ;;
        *)
            print_error "Unknown service: $1"
            exit 1
            ;;
    esac
}

# View logs
view_logs() {
    case $1 in
        main|"")
            print_header "Viewing Main Service Logs"
            docker-compose logs -f
            ;;
        minecraft)
            print_header "Viewing Minecraft Logs"
            docker-compose -f docker-compose.minecraft.yml logs -f
            ;;
        windows)
            print_header "Viewing Windows VM Logs"
            docker-compose -f docker-compose.windows.yml logs -f
            ;;
        all)
            print_header "Viewing All Logs"
            docker-compose logs -f &
            docker-compose -f docker-compose.minecraft.yml logs -f &
            docker-compose -f docker-compose.windows.yml logs -f
            ;;
        *)
            print_error "Unknown service: $1"
            exit 1
            ;;
    esac
}

# Show status
show_status() {
    print_header "Service Status"
    echo ""
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -1
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tail -n +2
    echo ""
    
    # Count services
    total=$(docker ps -q | wc -l)
    healthy=$(docker ps --filter "health=healthy" -q | wc -l)
    unhealthy=$(docker ps --filter "health=unhealthy" -q | wc -l)
    
    echo -e "${GREEN}Running: $total${NC} | ${GREEN}Healthy: $healthy${NC} | ${RED}Unhealthy: $unhealthy${NC}"
    echo ""
}

# Update services
update_service() {
    case $1 in
        main|"")
            print_header "Updating Main Services"
            docker-compose pull
            docker-compose up -d
            print_success "Main services updated"
            ;;
        minecraft)
            print_header "Updating Minecraft Server"
            docker-compose -f docker-compose.minecraft.yml pull
            docker-compose -f docker-compose.minecraft.yml up -d
            print_success "Minecraft server updated"
            ;;
        windows)
            print_header "Updating Windows VM"
            docker-compose -f docker-compose.windows.yml pull
            docker-compose -f docker-compose.windows.yml up -d
            print_success "Windows VM updated"
            ;;
        all)
            print_header "Updating All Services"
            docker-compose pull
            docker-compose -f docker-compose.minecraft.yml pull
            docker-compose -f docker-compose.windows.yml pull
            print_success "All images pulled"
            
            docker-compose up -d
            docker-compose -f docker-compose.minecraft.yml up -d
            docker-compose -f docker-compose.windows.yml up -d
            print_success "All services updated"
            ;;
        *)
            print_error "Unknown service: $1"
            exit 1
            ;;
    esac
}

# Main script logic
case $1 in
    start)
        start_service "$2"
        ;;
    stop)
        stop_service "$2"
        ;;
    restart)
        restart_service "$2"
        ;;
    logs)
        view_logs "$2"
        ;;
    status)
        show_status
        ;;
    update)
        update_service "$2"
        ;;
    init)
        init_directories
        ;;
    help|--help|-h|"")
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
