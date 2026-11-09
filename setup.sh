#!/usr/bin/env bash
# Calliope Linux setup - idempotent, safe to re-run
#
# Usage:
#   ./setup.sh          # Install backend + frontend dependencies
#   ./setup.sh --force  # Force reinstall of all dependencies

set -Eeuo pipefail

# Resolve script and repo root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR"
BACKEND="$ROOT/calliope-backend"
WEB="$ROOT/calliope-web"

# Colors for output (optional, safe to disable if not supported)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
FORCE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "============================================"
echo "Calliope first-time setup - idempotent, safe to re-run"
echo "============================================"
echo ""

# Check for required commands
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[Error] python3 not found. Please install Python 3.8+ first.${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}[Error] npm not found. Please install Node.js and npm first.${NC}"
    exit 1
fi

echo -e "${GREEN}[✓] Prerequisites found: python3, npm${NC}"
echo ""

# Backend setup
echo "[1/2] Setting up backend..."

if [[ ! -d "$BACKEND/.venv" || "$FORCE" == true ]]; then
    echo "  Creating Python virtual environment..."
    python3 -m venv "$BACKEND/.venv"
    
    echo "  Upgrading pip..."
    "$BACKEND/.venv/bin/python" -m pip install --upgrade pip
    
    echo "  Installing backend dependencies (editable mode with dev extras)..."
    cd "$BACKEND"
    "$BACKEND/.venv/bin/pip" install -e ".[dev]"
    cd "$ROOT"
    echo -e "${GREEN}  Backend setup complete${NC}"
else
    echo -e "${YELLOW}  Backend already installed - skipping (use --force to reinstall)${NC}"
fi

echo ""

# Frontend setup
echo "[2/2] Setting up frontend..."

if [[ ! -d "$WEB/node_modules" || "$FORCE" == true ]]; then
    echo "  Installing npm dependencies..."
    cd "$WEB"
    npm install
    cd "$ROOT"
    echo -e "${GREEN}  Frontend setup complete${NC}"
else
    echo -e "${YELLOW}  Frontend already installed - skipping (use --force to reinstall)${NC}"
fi

echo ""
echo "============================================"
echo -e "${GREEN}Setup complete!${NC}"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Configure your LLM and ComfyUI settings:"
echo "     - Copy calliope_config.example.json to calliope_config.json"
echo "     - Or configure them in the Settings page after starting the app"
echo ""
echo "  2. Start development servers (manual):"
echo "     ./start.sh"
echo ""
echo "  3. Or install as background systemd services:"
echo "     sudo ./install.sh"
echo "     systemctl status calliope-backend"
echo "     systemctl status calliope-web"
echo ""
