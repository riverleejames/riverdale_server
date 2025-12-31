#!/bin/bash
# Transmission P2P Speed Optimization Script
# This script optimizes Transmission settings for better P2P performance with VPN

set -e

echo "🚀 Optimizing Transmission for P2P speed..."

# Stop Transmission to modify settings
echo "📦 Stopping Transmission container..."
docker stop transmission

# Backup current settings
echo "💾 Backing up current settings..."
docker cp transmission:/config/settings.json /tmp/transmission-settings-backup-$(date +%Y%m%d-%H%M%S).json 2>/dev/null || echo "Backup skipped (container stopped)"

# Create optimized settings file
echo "⚙️  Applying optimized settings..."

# Create a temporary settings file with optimizations
cat > /tmp/transmission-optimized.json << 'EOF'
{
    "alt-speed-down": 50,
    "alt-speed-enabled": false,
    "alt-speed-time-begin": 540,
    "alt-speed-time-day": 127,
    "alt-speed-time-enabled": false,
    "alt-speed-time-end": 1020,
    "alt-speed-up": 50,
    "announce-ip": "",
    "announce-ip-enabled": false,
    "anti-brute-force-enabled": false,
    "anti-brute-force-threshold": 100,
    "bind-address-ipv4": "0.0.0.0",
    "bind-address-ipv6": "::",
    "blocklist-enabled": false,
    "blocklist-url": "http://www.example.com/blocklist",
    "cache-size-mb": 32,
    "default-trackers": "",
    "dht-enabled": true,
    "download-dir": "/downloads/complete",
    "download-queue-enabled": true,
    "download-queue-size": 10,
    "encryption": 2,
    "idle-seeding-limit": 30,
    "idle-seeding-limit-enabled": true,
    "incomplete-dir": "/downloads/incomplete",
    "incomplete-dir-enabled": true,
    "lpd-enabled": true,
    "message-level": 2,
    "peer-congestion-algorithm": "",
    "peer-id-ttl-hours": 6,
    "peer-limit-global": 800,
    "peer-limit-per-torrent": 150,
    "peer-port": 51413,
    "peer-port-random-high": 65535,
    "peer-port-random-low": 49152,
    "peer-port-random-on-start": false,
    "peer-socket-tos": "default",
    "pex-enabled": true,
    "port-forwarding-enabled": true,
    "preallocation": 1,
    "prefetch-enabled": true,
    "queue-stalled-enabled": true,
    "queue-stalled-minutes": 30,
    "ratio-limit": 2,
    "ratio-limit-enabled": false,
    "rename-partial-files": true,
    "rpc-authentication-required": true,
    "rpc-bind-address": "0.0.0.0",
    "rpc-enabled": true,
    "rpc-host-whitelist": "127.0.0.1",
    "rpc-host-whitelist-enabled": false,
    "rpc-password": "{7eac199b79b61bd5112584652f9704387f1ec834It0dgXCB",
    "rpc-port": 9091,
    "rpc-socket-mode": "0750",
    "rpc-url": "/transmission/",
    "rpc-username": "river",
    "rpc-whitelist": "127.0.0.1",
    "rpc-whitelist-enabled": false,
    "scrape-paused-torrents-enabled": true,
    "script-torrent-added-enabled": false,
    "script-torrent-added-filename": "",
    "script-torrent-done-enabled": false,
    "script-torrent-done-filename": "",
    "script-torrent-done-seeding-enabled": false,
    "script-torrent-done-seeding-filename": "",
    "seed-queue-enabled": false,
    "seed-queue-size": 20,
    "speed-limit-down": 0,
    "speed-limit-down-enabled": false,
    "speed-limit-up": 0,
    "speed-limit-up-enabled": false,
    "start-added-torrents": true,
    "tcp-enabled": true,
    "torrent-added-verify-mode": "fast",
    "trash-original-torrent-files": false,
    "umask": "002",
    "upload-slots-per-torrent": 20,
    "utp-enabled": true,
    "watch-dir": "/watch",
    "watch-dir-enabled": true
}
EOF

# Copy optimized settings to config directory
CONFIG_ROOT=${CONFIG_ROOT:-/mnt/media-storage/config}
cp /tmp/transmission-optimized.json ${CONFIG_ROOT}/transmission/settings.json

# Set proper permissions
sudo chown ${PUID:-1000}:${PGID:-1000} ${CONFIG_ROOT}/transmission/settings.json

echo "✅ Optimized settings applied!"

# Start Transmission
echo "🚀 Starting Transmission container..."
docker start transmission

# Wait for startup
echo "⏳ Waiting for Transmission to start..."
sleep 5

echo ""
echo "✨ Optimization Complete!"
echo ""
echo "📊 Key Changes Applied:"
echo "  • Peer limit increased: 200 → 800 (global)"
echo "  • Per-torrent peers: 50 → 150"
echo "  • Cache size increased: 4MB → 32MB"
echo "  • Upload slots: 14 → 20"
echo "  • Encryption: Preferred → Required"
echo "  • Download queue: Disabled → Enabled (10 simultaneous)"
echo "  • Seed queue: Enabled → Disabled (unlimited seeding)"
echo "  • Ratio limit: Removed for better peer reputation"
echo ""
echo "🔍 Additional Recommendations:"
echo "  1. Check NordVPN connection: nordvpn status"
echo "  2. Verify P2P server: nordvpn settings | grep P2P"
echo "  3. Monitor speeds in Transmission or Flood UI"
echo "  4. Consider enabling NordVPN's split tunneling if available"
echo ""
echo "⚠️  Note: Without proper port forwarding, incoming connections"
echo "    will be limited. Consider NordVPN's port forwarding feature"
echo "    or switching to a VPN provider that supports it better."
echo ""
