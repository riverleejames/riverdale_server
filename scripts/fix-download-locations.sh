#!/bin/bash

# Automated Download Location Fix Script
# This script moves completed downloads from incorrect locations to where Sonarr/Radarr expect them

echo "=== Download Location Fix Script ==="
echo "Date: $(date)"
echo ""

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "❌ ERROR: .env file not found"
    exit 1
fi

echo "🔍 Scanning for misplaced completed downloads..."

# Function to move TV shows to Sonarr location
fix_tv_downloads() {
    echo "📺 Checking for TV show downloads in wrong location..."
    
    # Find video files in incomplete directory
    find /mnt/media-storage/downloads/incomplete -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" | while read file; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            echo "  📁 Found: $filename"
            
            # Create directory structure for Sonarr
            target_dir="/mnt/media-storage/downloads/complete/tv-sonarr/$filename"
            mkdir -p "$target_dir"
            
            # Move file to proper location
            mv "$file" "$target_dir/"
            
            echo "  ✅ Moved: $filename → /downloads/complete/tv-sonarr/"
        fi
    done
}

# Function to check Transmission status and move completed downloads
fix_transmission_completed() {
    echo "🔄 Checking Transmission for completed downloads..."
    
    # Get list of completed torrents
    completed=$(docker exec transmission transmission-remote -n river:ca7uwaxa -l | grep "100%" | grep "Idle")
    
    if [[ -n "$completed" ]]; then
        echo "  📋 Found completed torrents that may need relocation:"
        echo "$completed"
    else
        echo "  ℹ️  No idle completed torrents found"
    fi
}

# Function to fix ownership and permissions
fix_permissions() {
    echo "🔧 Fixing ownership and permissions..."
    
    # Fix ownership of moved files
    chown -R $PUID:$PGID /mnt/media-storage/downloads/complete/ 2>/dev/null || sudo chown -R $PUID:$PGID /mnt/media-storage/downloads/complete/
    
    # Set proper permissions
    find /mnt/media-storage/downloads/complete -type d -exec chmod 755 {} \; 2>/dev/null
    find /mnt/media-storage/downloads/complete -type f -exec chmod 644 {} \; 2>/dev/null
    
    echo "  ✅ Permissions updated"
}

# Function to trigger import scans
trigger_imports() {
    echo "🔄 Triggering import scans..."
    
    # Restart Sonarr to trigger scan
    echo "  📺 Restarting Sonarr..."
    docker-compose restart sonarr
    
    # Wait for Sonarr to start
    sleep 10
    
    echo "  ✅ Import scans triggered"
}

# Main execution
echo "🚀 Starting download location fixes..."

# Check current status
echo ""
echo "📊 Current download directory status:"
echo "  Incomplete: $(find /mnt/media-storage/downloads/incomplete -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" 2>/dev/null | wc -l) video files"
echo "  Complete/TV: $(find /mnt/media-storage/downloads/complete/tv-sonarr -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" 2>/dev/null | wc -l) video files"
echo "  Complete/Movies: $(find /mnt/media-storage/downloads/complete/radarr -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" 2>/dev/null | wc -l) video files"

echo ""
# Execute fixes
fix_tv_downloads
echo ""
fix_transmission_completed
echo ""
fix_permissions
echo ""
trigger_imports

echo ""
echo "📊 Final status:"
echo "  Incomplete: $(find /mnt/media-storage/downloads/incomplete -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" 2>/dev/null | wc -l) video files"
echo "  Complete/TV: $(find /mnt/media-storage/downloads/complete/tv-sonarr -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" 2>/dev/null | wc -l) video files"
echo "  Complete/Movies: $(find /mnt/media-storage/downloads/complete/radarr -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" 2>/dev/null | wc -l) video files"

echo ""
echo "✅ Download location fix complete!"
echo ""
echo "💡 Next steps:"
echo "  1. Configure Sonarr download client: http://sonarr.river.local:8989/settings/downloadclients"
echo "  2. Check Sonarr activity: http://sonarr.river.local:8989/activity/queue"
echo "  3. Monitor logs: docker-compose logs -f sonarr"
