#!/usr/bin/env bash
# Calliope stop script
#
# Stops both local development servers (started with start.sh) or systemd services.
# 
# Usage:
#   ./stop.sh         # Stop services (local or systemd, whichever is running)
#   ./stop.sh local   # Stop only local dev servers
#   ./stop.sh systemd # Stop only systemd services

set -Eeuo pipefail

# Resolve script and repo root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

MODE="${1:-auto}"  # auto, local, systemd

echo "============================================"
echo "Calliope service shutdown"
echo "============================================"
echo ""

# Try to stop systemd services if running as root or if requested
if [[ "$MODE" != "local" ]]; then
    if systemctl is-active --quiet calliope-backend.service 2>/dev/null; then
        echo -e "${BLUE}[systemd]${NC} Stopping calliope-backend.service..."
        systemctl stop calliope-backend.service
        echo -e "${GREEN}[✓] Backend stopped${NC}"
    fi

    if systemctl is-active --quiet calliope-web.service 2>/dev/null; then
        echo -e "${BLUE}[systemd]${NC} Stopping calliope-web.service..."
        systemctl stop calliope-web.service
        echo -e "${GREEN}[✓] Frontend stopped${NC}"
    fi
fi

# Try to stop local dev servers if requested
if [[ "$MODE" != "systemd" ]]; then
    if [[ -f "$ROOT/.calliope-pids" ]]; then
        echo -e "${BLUE}[local]${NC} Stopping local dev servers..."
        while IFS= read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                echo "  Terminating PID $pid..."
                kill "$pid" || true
            fi
        done < "$ROOT/.calliope-pids"
        rm -f "$ROOT/.calliope-pids"
        echo -e "${GREEN}[✓] Local servers stopped${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Done!${NC}"
