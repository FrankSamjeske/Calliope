#!/usr/bin/env bash
# Calliope local development start script
# 
# Starts backend and frontend in the foreground (not as systemd services).
# Useful for development work without installing systemd services.
#
# Requires: ./setup.sh to have been run first

set -Eeuo pipefail

# Resolve script and repo root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR"
BACKEND="$ROOT/calliope-backend"
WEB="$ROOT/calliope-web"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "============================================"
echo "Calliope development server startup"
echo "============================================"
echo ""

# Validate prerequisites
if [[ ! -d "$BACKEND/.venv" ]]; then
    echo -e "${RED}[Error] Backend not installed${NC}"
    echo "Please run: ./setup.sh"
    exit 1
fi

if [[ ! -d "$WEB/node_modules" ]]; then
    echo -e "${RED}[Error] Frontend not installed${NC}"
    echo "Please run: ./setup.sh"
    exit 1
fi

# Create logs directory
mkdir -p "$ROOT/logs"

echo -e "${GREEN}[✓] Prerequisites OK${NC}"
echo ""
echo "Starting services in background (logs in $ROOT/logs/)..."
echo ""

# Start backend in background
echo -e "${BLUE}[Backend]${NC} Starting on 127.0.0.1:8247 (or CALLIOPE_HOST:CALLIOPE_PORT)"
cd "$BACKEND"
"$BACKEND/.venv/bin/python" -m calliope.main \
    > "$ROOT/logs/backend.log" 2>&1 &
BACKEND_PID=$!
echo -e "${GREEN}  PID: $BACKEND_PID${NC}"
cd "$ROOT"

# Wait a moment for backend to start
sleep 2

# Start frontend in background
echo -e "${BLUE}[Frontend]${NC} Starting on 127.0.0.1:5173 (or CALLIOPE_WEB_HOST:CALLIOPE_WEB_PORT)"
cd "$WEB"
npm run dev \
    > "$ROOT/logs/web.log" 2>&1 &
WEB_PID=$!
echo -e "${GREEN}  PID: $WEB_PID${NC}"
cd "$ROOT"

echo ""
echo "============================================"
echo -e "${GREEN}Services started!${NC}"
echo "============================================"
echo ""
echo "Access the frontend:"
echo -e "  ${BLUE}http://127.0.0.1:5173${NC}"
echo ""
echo "Backend API:"
echo -e "  ${BLUE}http://127.0.0.1:8247${NC}"
echo ""
echo "Logs:"
echo -e "  ${BLUE}tail -f $ROOT/logs/backend.log${NC}"
echo -e "  ${BLUE}tail -f $ROOT/logs/web.log${NC}"
echo ""
echo "To stop services, run:"
echo -e "  ${BLUE}./stop.sh${NC}"
echo ""

# Save PIDs to a file for stop.sh
echo "$BACKEND_PID" > "$ROOT/.calliope-pids"
echo "$WEB_PID" >> "$ROOT/.calliope-pids"

# Keep script running to show logs
trap "kill $BACKEND_PID $WEB_PID 2>/dev/null; rm -f $ROOT/.calliope-pids" EXIT

echo "Press Ctrl+C to stop services..."
wait
