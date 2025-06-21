#!/bin/bash

# Permission Health Check Script for Riverdale Media Server
# This script checks for permission issues across all services

echo "=== Riverdale Media Server Permission Health Check ==="
echo "Date: $(date)"
echo ""

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "❌ ERROR: .env file not found"
    exit 1
fi

echo "🔍 Checking host system permissions..."

# Check base directory ownership
echo "📁 Base directory ownership:"
ls -ld /mnt/media-storage/{config,downloads,media} 2>/dev/null || echo "  ⚠️  Some base directories don't exist"

echo ""
echo "📂 Download directory structure:"
find /mnt/media-storage/downloads -maxdepth 3 -type d -exec ls -ld {} \; 2>/dev/null | head -10

echo ""
echo "🎬 Media directory ownership:"
ls -la /mnt/media-storage/media/ 2>/dev/null || echo "  ⚠️  Media directory doesn't exist"

echo ""
echo "⚙️  Config directory ownership:"
ls -la /mnt/media-storage/config/ 2>/dev/null | grep -E "^d" | head -5

echo ""
echo "🔍 Checking container user mappings..."

# Check each service's user mapping
services=("sonarr" "radarr" "transmission" "jellyfin" "prowlarr")
for service in "${services[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "^$service$"; then
        echo "📺 $service container:"
        echo "  User ID: $(docker exec $service id 2>/dev/null || echo 'Container not running')"
        echo "  Downloads access: $(docker exec $service ls -ld /downloads 2>/dev/null | awk '{print $1" "$3" "$4}' || echo 'No access')"
    else
        echo "⚠️  $service: Container not running"
    fi
done

echo ""
echo "🔍 Checking non-LinuxServer containers..."

# Check Dashy
if docker ps --format "table {{.Names}}" | grep -q "^dashy$"; then
    echo "📊 Dashy container:"
    echo "  User ID: $(docker exec dashy id 2>/dev/null)"
    echo "  Config access: $(docker exec dashy ls -ld /app/user-data 2>/dev/null | awk '{print $1" "$3" "$4}' || echo 'No config mount')"
else
    echo "⚠️  Dashy: Container not running"
fi

# Check Glances
if docker ps --format "table {{.Names}}" | grep -q "^glances$"; then
    echo "📈 Glances container:"
    echo "  User ID: $(docker exec glances id 2>/dev/null)"
    echo "  Docker socket access: $(docker exec glances ls -l /var/run/docker.sock 2>/dev/null | awk '{print $1" "$3" "$4}' || echo 'No socket access')"
else
    echo "⚠️  Glances: Container not running"
fi

echo ""
echo "🔍 Checking for permission conflicts..."

# Find files not owned by the correct user in critical directories
echo "🚨 Files not owned by PUID:PGID ($PUID:$PGID):"
wrong_owner_downloads=$(find /mnt/media-storage/downloads -not -user $PUID -o -not -group $PGID 2>/dev/null | wc -l)
wrong_owner_config=$(find /mnt/media-storage/config -not -user $PUID -o -not -group $PGID 2>/dev/null | wc -l)
wrong_owner_media=$(find /mnt/media-storage/media -not -user $PUID -o -not -group $PGID 2>/dev/null | wc -l)

echo "  Downloads: $wrong_owner_downloads files with wrong ownership"
echo "  Config: $wrong_owner_config files with wrong ownership"
echo "  Media: $wrong_owner_media files with wrong ownership"

if [ $wrong_owner_downloads -gt 0 ]; then
    echo "  🔍 Sample files with wrong ownership in downloads:"
    find /mnt/media-storage/downloads -not -user $PUID -o -not -group $PGID 2>/dev/null | head -5
fi

echo ""
echo "🔍 Checking import-ready files..."

# Check for files that might have import issues
echo "📥 Recent downloads that might need attention:"
find /mnt/media-storage/downloads/complete -type f -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" | \
    xargs ls -la 2>/dev/null | head -5 | while read line; do
        permissions=$(echo $line | awk '{print $1}')
        owner=$(echo $line | awk '{print $3}')
        group=$(echo $line | awk '{print $4}')
        file=$(echo $line | awk '{print $9}')
        
        if [[ $owner != "$(id -un $PUID)" ]] || [[ $group != "$(id -gn $PGID)" ]]; then
            echo "  ⚠️  $file - Owner: $owner:$group (should be $(id -un $PUID):$(id -gn $PGID))"
        fi
    done

echo ""
echo "💡 Recommendations:"

if [ $wrong_owner_downloads -gt 0 ] || [ $wrong_owner_config -gt 0 ] || [ $wrong_owner_media -gt 0 ]; then
    echo "  1. Run init container to fix permissions: docker-compose restart init-directories"
fi

echo "  2. Monitor container logs for permission errors: docker-compose logs [service]"
echo "  3. For import issues, check Sonarr/Radarr activity logs"
echo "  4. Ensure new downloads maintain correct permissions"

echo ""
echo "✅ Permission health check complete!"
