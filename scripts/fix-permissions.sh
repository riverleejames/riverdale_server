#!/bin/bash

# Permission Fix Script for Riverdale Media Server
# This script fixes common permission issues

echo "=== Riverdale Media Server Permission Fix ==="
echo "Date: $(date)"
echo ""

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "❌ ERROR: .env file not found"
    exit 1
fi

echo "🔧 Starting permission fixes..."

# Confirm before making changes
read -p "This will modify file permissions. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo "🏃 Running init container to ensure directory structure..."
docker-compose restart init-directories

echo "⏳ Waiting for init container to complete..."
sleep 5

echo "🔧 Fixing ownership of all media server files..."

# Fix ownership
echo "  📁 Fixing downloads directory ownership..."
sudo chown -R $PUID:$PGID /mnt/media-storage/downloads/ 2>/dev/null || echo "    ⚠️  Need sudo for some files"

echo "  📁 Fixing media directory ownership..."
sudo chown -R $PUID:$PGID /mnt/media-storage/media/ 2>/dev/null || echo "    ⚠️  Need sudo for some files"

echo "  📁 Fixing config directory ownership..."
sudo chown -R $PUID:$PGID /mnt/media-storage/config/ 2>/dev/null || echo "    ⚠️  Need sudo for some files"

# Fix permissions
echo "🔧 Setting proper permissions..."

echo "  📁 Setting directory permissions (755)..."
find /mnt/media-storage/downloads /mnt/media-storage/media /mnt/media-storage/config -type d -exec chmod 755 {} \; 2>/dev/null

echo "  📄 Setting file permissions (644 for media files)..."
find /mnt/media-storage/downloads /mnt/media-storage/media -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.mov" -o -name "*.m4v" \) -exec chmod 644 {} \; 2>/dev/null

echo "  📄 Setting executable permissions for scripts and binaries..."
find /mnt/media-storage/config -type f -name "*.sh" -exec chmod 755 {} \; 2>/dev/null

echo "🔄 Restarting containers that might need permission refresh..."
docker-compose restart dashy

echo "✅ Permission fixes complete!"
echo ""
echo "🔍 Running permission health check..."
./permission-health-check.sh
