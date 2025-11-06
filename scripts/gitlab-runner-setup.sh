#!/bin/bash
# GitLab Runner Setup Script
# This script helps you set up and register a GitLab Runner

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}GitLab Runner Setup Script${NC}"
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

# Start the GitLab Runner container
echo -e "${YELLOW}Starting GitLab Runner container...${NC}"
$DOCKER_COMPOSE -f docker-compose.gitlab-runner.yml up -d

echo ""
echo -e "${GREEN}GitLab Runner container started!${NC}"
echo ""
echo -e "${YELLOW}To register the runner, you have two options:${NC}"
echo ""
echo "Option 1: Interactive Registration"
echo "-----------------------------------"
echo "Run the following command and follow the prompts:"
echo ""
echo -e "${GREEN}docker exec -it gitlab-runner gitlab-runner register${NC}"
echo ""
echo "You'll need:"
echo "  - GitLab instance URL (e.g., https://gitlab.com)"
echo "  - Registration token (from your GitLab project/group Settings > CI/CD > Runners)"
echo "  - Runner description (e.g., 'riverdale-docker-runner')"
echo "  - Runner tags (e.g., 'docker,linux')"
echo "  - Executor: docker"
echo "  - Default Docker image (e.g., 'alpine:latest' or 'docker:latest')"
echo ""
echo "Option 2: Non-Interactive Registration"
echo "---------------------------------------"
echo "Run the following command with your values:"
echo ""
echo -e "${GREEN}docker exec gitlab-runner gitlab-runner register \\"
echo "  --non-interactive \\"
echo "  --url \"https://gitlab.com\" \\"
echo "  --registration-token \"YOUR_TOKEN\" \\"
echo "  --executor \"docker\" \\"
echo "  --docker-image alpine:latest \\"
echo "  --description \"riverdale-docker-runner\" \\"
echo "  --tag-list \"docker,linux\" \\"
echo "  --run-untagged=\"true\" \\"
echo "  --locked=\"false\" \\"
echo "  --docker-privileged=\"false\" \\"
echo "  --docker-volumes \"/var/run/docker.sock:/var/run/docker.sock\"${NC}"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "-----------------------------------"
echo "Check runner status:"
echo "  docker exec gitlab-runner gitlab-runner list"
echo ""
echo "View runner logs:"
echo "  docker logs -f gitlab-runner"
echo ""
echo "Stop runner:"
echo "  $DOCKER_COMPOSE -f docker-compose.gitlab-runner.yml down"
echo ""
echo "Restart runner:"
echo "  $DOCKER_COMPOSE -f docker-compose.gitlab-runner.yml restart"
echo ""
echo "Unregister a runner:"
echo "  docker exec gitlab-runner gitlab-runner unregister --name RUNNER_NAME"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
