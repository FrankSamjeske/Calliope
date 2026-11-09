#!/usr/bin/env bash
# Calliope service status script
#
# Shows the status of Calliope services.
# Checks both local dev servers and systemd services.

set -Eeuo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "============================================"
echo "Calliope service status"
echo "============================================"
echo ""

# Check systemd services
echo -e "${BLUE}Systemd Services:${NC}"

if systemctl list-units --all | grep -q calliope-backend.service; then
    if systemctl is-active --quiet calliope-backend.service; then
        echo -e "  ${GREEN}[●]${NC} calliope-backend.service (active)"
        systemctl status calliope-backend.service --no-pager | tail -3 | sed 's/^/    /'
    else
        echo -e "  ${RED}[○]${NC} calliope-backend.service (inactive)"
    fi
else
    echo -e "  ${YELLOW}[-]${NC} calliope-backend.service (not installed)"
fi

if systemctl list-units --all | grep -q calliope-web.service; then
    if systemctl is-active --quiet calliope-web.service; then
        echo -e "  ${GREEN}[●]${NC} calliope-web.service (active)"
        systemctl status calliope-web.service --no-pager | tail -3 | sed 's/^/    /'
    else
        echo -e "  ${RED}[○]${NC} calliope-web.service (inactive)"
    fi
else
    echo -e "  ${YELLOW}[-]${NC} calliope-web.service (not installed)"
fi

echo ""

# Check local dev servers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR"

echo -e "${BLUE}Local Dev Servers:${NC}"

if [[ -f "$ROOT/.calliope-pids" ]]; then
    backend_pid=$(sed -n '1p' "$ROOT/.calliope-pids")
    web_pid=$(sed -n '2p' "$ROOT/.calliope-pids")
    
    if kill -0 "$backend_pid" 2>/dev/null; then
        echo -e "  ${GREEN}[●]${NC} Backend dev server (PID $backend_pid)"
    else
        echo -e "  ${RED}[○]${NC} Backend dev server (PID $backend_pid - not running)"
    fi
    
    if kill -0 "$web_pid" 2>/dev/null; then
        echo -e "  ${GREEN}[●]${NC} Frontend dev server (PID $web_pid)"
    else
        echo -e "  ${RED}[○]${NC} Frontend dev server (PID $web_pid - not running)"
    fi
else
    echo -e "  ${YELLOW}[-]${NC} No local dev servers running"
fi

echo ""
echo "Useful commands:"
echo -e "  ${BLUE}systemctl status calliope-backend${NC}"
echo -e "  ${BLUE}systemctl status calliope-web${NC}"
echo -e "  ${BLUE}journalctl -u calliope-backend -f${NC}"
echo -e "  ${BLUE}journalctl -u calliope-web -f${NC}"
