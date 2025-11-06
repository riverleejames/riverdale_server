#!/bin/bash
# Quick reference commands for GitLab Runner management

# Start GitLab Runner
start_runner() {
    docker compose -f docker-compose.gitlab-runner.yml up -d
    echo "GitLab Runner started"
}

# Stop GitLab Runner
stop_runner() {
    docker compose -f docker-compose.gitlab-runner.yml down
    echo "GitLab Runner stopped"
}

# Restart GitLab Runner
restart_runner() {
    docker compose -f docker-compose.gitlab-runner.yml restart
    echo "GitLab Runner restarted"
}

# View runner logs
logs_runner() {
    docker logs -f gitlab-runner
}

# List registered runners
list_runners() {
    docker exec gitlab-runner gitlab-runner list
}

# Verify runner registration
verify_runner() {
    docker exec gitlab-runner gitlab-runner verify
}

# Interactive registration
register_interactive() {
    docker exec -it gitlab-runner gitlab-runner register
}

# Show help
show_help() {
    echo "GitLab Runner Management Commands"
    echo "=================================="
    echo ""
    echo "Usage: source scripts/gitlab-runner-commands.sh && <command>"
    echo ""
    echo "Available commands:"
    echo "  start_runner          - Start the GitLab Runner container"
    echo "  stop_runner           - Stop the GitLab Runner container"
    echo "  restart_runner        - Restart the GitLab Runner container"
    echo "  logs_runner           - View GitLab Runner logs (follow mode)"
    echo "  list_runners          - List all registered runners"
    echo "  verify_runner         - Verify runner registration status"
    echo "  register_interactive  - Register a new runner (interactive)"
    echo "  show_help             - Show this help message"
    echo ""
    echo "Example:"
    echo "  source scripts/gitlab-runner-commands.sh && start_runner"
}

# If script is sourced, show help
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly"
    echo "Usage: source scripts/gitlab-runner-commands.sh && <command>"
    show_help
fi
