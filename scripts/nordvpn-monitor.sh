#!/bin/bash
# NordVPN Monitor and Auto-Reconnect Script
# Checks VPN connection and refreshes every 2-3 hours to P2P servers

set -e

LOG_FILE="/var/log/nordvpn-monitor.log"
MAX_UPTIME_HOURS=2

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if NordVPN is connected
is_connected() {
    nordvpn status | grep -q "Status: Connected"
}

# Function to get uptime in hours
get_uptime_hours() {
    local uptime_str=$(nordvpn status | grep "Uptime:" | awk '{print $2, $3}')
    local value=$(echo "$uptime_str" | awk '{print $1}')
    local unit=$(echo "$uptime_str" | awk '{print $2}')
    
    case "$unit" in
        hour|hours)
            echo "$value"
            ;;
        day|days)
            echo "$(awk "BEGIN {print $value * 24}")"
            ;;
        minute|minutes)
            echo "0"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Function to check if on P2P server
is_p2p_server() {
    # NordVPN doesn't explicitly show P2P in status, but we can check for P2P countries
    local country=$(nordvpn status | grep "Country:" | awk '{print $2}')
    # Major P2P countries: Netherlands, Switzerland, Spain, etc.
    [[ "$country" =~ ^(Netherlands|Switzerland|Spain|Canada|Sweden|Romania)$ ]]
}

# Function to reconnect to P2P server
reconnect_p2p() {
    log_message "🔄 Reconnecting to P2P server..."
    
    # Disconnect first
    nordvpn disconnect 2>&1 | tee -a "$LOG_FILE" || true
    sleep 2
    
    # Connect to P2P group
    nordvpn connect p2p 2>&1 | tee -a "$LOG_FILE"
    sleep 3
    
    # Verify connection
    if is_connected; then
        local server=$(nordvpn status | grep "Hostname:" | awk '{print $2}')
        local country=$(nordvpn status | grep "Country:" | awk '{print $2}')
        log_message "✅ Successfully connected to $server ($country)"
        
        # Restart Transmission to refresh connection through new VPN route
        log_message "🔄 Restarting Transmission to refresh connection..."
        docker restart transmission 2>&1 | tee -a "$LOG_FILE"
        sleep 5
        log_message "✅ Transmission restarted"
    else
        log_message "❌ Failed to reconnect to VPN"
        return 1
    fi
}

# Main monitoring logic
log_message "=== NordVPN Monitor Check ==="

# Check if connected
if ! is_connected; then
    log_message "⚠️  VPN is disconnected! Attempting to reconnect..."
    reconnect_p2p
    exit 0
fi

# Check uptime
uptime_hours=$(get_uptime_hours)
log_message "📊 Current VPN uptime: ${uptime_hours} hours"

# Check if uptime exceeds threshold or not on P2P server
if (( $(awk "BEGIN {print ($uptime_hours >= $MAX_UPTIME_HOURS)}") )); then
    log_message "⏰ VPN uptime exceeds ${MAX_UPTIME_HOURS} hours - refreshing connection"
    reconnect_p2p
elif ! is_p2p_server; then
    log_message "⚠️  Not connected to P2P-optimized server - switching..."
    reconnect_p2p
else
    local server=$(nordvpn status | grep "Hostname:" | awk '{print $2}')
    local country=$(nordvpn status | grep "Country:" | awk '{print $2}')
    log_message "✅ VPN healthy: $server ($country)"
fi

log_message "=== Monitor check complete ==="
echo ""
