#!/bin/bash
# NordVPN Monitor Management Script
# Quick commands for managing the NordVPN monitoring system

ACTION=${1:-help}

case "$ACTION" in
    status)
        echo "=== NordVPN Monitor Status ==="
        sudo systemctl status nordvpn-monitor.timer
        echo ""
        echo "=== Next Scheduled Run ==="
        sudo systemctl list-timers nordvpn-monitor.timer
        ;;
    
    logs)
        echo "=== Recent NordVPN Monitor Logs ==="
        tail -50 /var/log/nordvpn-monitor.log
        ;;
    
    logs-live)
        echo "=== Live NordVPN Monitor Logs (Ctrl+C to exit) ==="
        tail -f /var/log/nordvpn-monitor.log
        ;;
    
    run-now)
        echo "=== Running Monitor Check Now ==="
        /home/river/riverdale_server/scripts/nordvpn-monitor.sh
        ;;
    
    enable)
        echo "=== Enabling NordVPN Monitor ==="
        sudo systemctl enable nordvpn-monitor.timer
        sudo systemctl start nordvpn-monitor.timer
        echo "✅ Monitor enabled and started"
        ;;
    
    disable)
        echo "=== Disabling NordVPN Monitor ==="
        sudo systemctl stop nordvpn-monitor.timer
        sudo systemctl disable nordvpn-monitor.timer
        echo "✅ Monitor disabled and stopped"
        ;;
    
    restart)
        echo "=== Restarting NordVPN Monitor ==="
        sudo systemctl restart nordvpn-monitor.timer
        echo "✅ Monitor restarted"
        ;;
    
    vpn-status)
        echo "=== NordVPN Connection Status ==="
        nordvpn status
        ;;
    
    reconnect)
        echo "=== Manually Reconnecting to P2P Server ==="
        nordvpn disconnect
        sleep 2
        nordvpn connect p2p
        echo ""
        echo "=== Restarting Transmission ==="
        docker restart transmission
        echo "✅ Done"
        ;;
    
    help|*)
        cat << 'EOF'
🔧 NordVPN Monitor Management

Usage: ./manage-nordvpn.sh [command]

Commands:
  status        Show timer status and next scheduled run
  logs          Show recent monitor logs
  logs-live     Watch logs in real-time
  run-now       Run a monitor check immediately
  enable        Enable and start the monitor
  disable       Disable and stop the monitor
  restart       Restart the monitor timer
  vpn-status    Show current VPN connection status
  reconnect     Manually reconnect to P2P server
  help          Show this help message

The monitor runs every 30 minutes and:
  • Checks if VPN is connected
  • Reconnects if disconnected
  • Refreshes connection every 2 hours
  • Ensures connection to P2P-optimized servers
  • Restarts Transmission after reconnection

Log file: /var/log/nordvpn-monitor.log
EOF
        ;;
esac
