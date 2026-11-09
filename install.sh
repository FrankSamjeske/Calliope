#!/usr/bin/env bash
# Calliope Linux systemd service installer
#
# Installs Calliope backend and frontend as systemd services.
# Requires root privileges (sudo).
#
# Usage:
#   sudo ./install.sh                # Install/update services (preserve env file)
#   sudo ./install.sh --overwrite-env # Install and overwrite environment config

set -Eeuo pipefail

# Resolve script and repo root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR"
BACKEND="$ROOT/calliope-backend"
WEB="$ROOT/calliope-web"
SCRIPTS="$ROOT/scripts/linux"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SYSTEMD_UNITS_DIR="/etc/systemd/system"
CALLIOPE_CONFIG_DIR="/etc/calliope"
CALLIOPE_ENV_FILE="$CALLIOPE_CONFIG_DIR/calliope.env"
BACKEND_SERVICE_TEMPLATE="$SCRIPTS/systemd/calliope-backend.service"
WEB_SERVICE_TEMPLATE="$SCRIPTS/systemd/calliope-web.service"
ENV_EXAMPLE="$SCRIPTS/calliope.env.example"

OVERWRITE_ENV=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --overwrite-env)
            OVERWRITE_ENV=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[Error] This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo "============================================"
echo "Calliope systemd service installer"
echo "============================================"
echo ""

# Validate prerequisites
echo "Validating prerequisites..."

if ! command -v systemctl &> /dev/null; then
    echo -e "${RED}[Error] systemctl not found. systemd is required.${NC}"
    exit 1
fi

if [[ ! -d "$BACKEND/.venv" ]]; then
    echo -e "${RED}[Error] Backend not installed: $BACKEND/.venv not found${NC}"
    echo "Please run ./setup.sh first"
    exit 1
fi

if [[ ! -d "$WEB/node_modules" ]]; then
    echo -e "${RED}[Error] Frontend not installed: $WEB/node_modules not found${NC}"
    echo "Please run ./setup.sh first"
    exit 1
fi

if [[ ! -f "$BACKEND_SERVICE_TEMPLATE" ]]; then
    echo -e "${RED}[Error] Backend service template not found: $BACKEND_SERVICE_TEMPLATE${NC}"
    exit 1
fi

if [[ ! -f "$WEB_SERVICE_TEMPLATE" ]]; then
    echo -e "${RED}[Error] Frontend service template not found: $WEB_SERVICE_TEMPLATE${NC}"
    exit 1
fi

echo -e "${GREEN}[✓] All prerequisites validated${NC}"
echo ""

# Create config directory
echo "Creating configuration directory..."
if [[ ! -d "$CALLIOPE_CONFIG_DIR" ]]; then
    mkdir -p "$CALLIOPE_CONFIG_DIR"
    chmod 755 "$CALLIOPE_CONFIG_DIR"
    echo -e "${GREEN}  Created $CALLIOPE_CONFIG_DIR${NC}"
else
    echo -e "${YELLOW}  Directory already exists: $CALLIOPE_CONFIG_DIR${NC}"
fi

# Install environment file
echo "Installing environment configuration..."
if [[ ! -f "$CALLIOPE_ENV_FILE" ]] || [[ "$OVERWRITE_ENV" == true ]]; then
    cp "$ENV_EXAMPLE" "$CALLIOPE_ENV_FILE"
    chmod 644 "$CALLIOPE_ENV_FILE"
    echo -e "${GREEN}  Installed: $CALLIOPE_ENV_FILE${NC}"
    echo "  Edit this file to customize host/port/API target"
else
    echo -e "${YELLOW}  Config already exists: $CALLIOPE_ENV_FILE${NC}"
    echo "  (use --overwrite-env to replace with defaults)"
fi

echo ""

# Substitute paths in service templates and install them
echo "Installing systemd service units..."

# Get the current user for reference
CURRENT_USER="$(stat -c '%U' "$ROOT")"
echo "  Repository owner: $CURRENT_USER"
echo "  Services will run as: root (edit $CALLIOPE_CONFIG_DIR/calliope.env to configure)"

# Backend service
echo "  Installing backend service..."
BACKEND_SERVICE_DEST="$SYSTEMD_UNITS_DIR/calliope-backend.service"
sed "s|%S|$CALLIOPE_CONFIG_DIR/..|g" "$BACKEND_SERVICE_TEMPLATE" > "$BACKEND_SERVICE_DEST"
chmod 644 "$BACKEND_SERVICE_DEST"
echo -e "${GREEN}    Installed: $BACKEND_SERVICE_DEST${NC}"

# Web service
echo "  Installing web service..."
WEB_SERVICE_DEST="$SYSTEMD_UNITS_DIR/calliope-web.service"
sed "s|%S|$CALLIOPE_CONFIG_DIR/..|g" "$WEB_SERVICE_TEMPLATE" > "$WEB_SERVICE_DEST"
chmod 644 "$WEB_SERVICE_DEST"
echo -e "${GREEN}    Installed: $WEB_SERVICE_DEST${NC}"

echo ""

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload
echo -e "${GREEN}[✓] systemd daemon reloaded${NC}"

echo ""

# Enable services
echo "Enabling services..."
systemctl enable calliope-backend.service
echo -e "${GREEN}  Enabled: calliope-backend.service${NC}"

systemctl enable calliope-web.service
echo -e "${GREEN}  Enabled: calliope-web.service${NC}"

echo ""

# Start services
echo "Starting services..."
systemctl restart calliope-backend.service
echo -e "${GREEN}  Started: calliope-backend.service${NC}"

systemctl restart calliope-web.service
echo -e "${GREEN}  Started: calliope-web.service${NC}"

echo ""
echo "============================================"
echo -e "${GREEN}Installation complete!${NC}"
echo "============================================"
echo ""
echo "Service status:"
echo -e "${BLUE}  systemctl status calliope-backend${NC}"
echo -e "${BLUE}  systemctl status calliope-web${NC}"
echo ""
echo "View logs:"
echo -e "${BLUE}  journalctl -u calliope-backend -f${NC}"
echo -e "${BLUE}  journalctl -u calliope-web -f${NC}"
echo ""
echo "Configuration:"
echo -e "${BLUE}  $CALLIOPE_ENV_FILE${NC}"
echo ""
echo "Manage services:"
echo -e "${BLUE}  systemctl stop calliope-backend calliope-web${NC}"
echo -e "${BLUE}  systemctl start calliope-backend calliope-web${NC}"
echo -e "${BLUE}  systemctl restart calliope-backend calliope-web${NC}"
echo -e "${BLUE}  systemctl disable calliope-backend calliope-web  # disable auto-start at boot${NC}"
echo ""
