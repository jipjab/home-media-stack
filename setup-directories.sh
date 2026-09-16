#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment
if [ ! -f .env ]; then
    log_warn ".env not found, using default: /home/media-stack"
    BASE_DIR="/home/media-stack"
else
    export $(grep -v '^#' .env | grep '^MEDIA_STORAGE_PATH' | xargs)
    BASE_DIR="${MEDIA_STORAGE_PATH:-/home/media-stack}"
fi

log_info "Creating directory structure in $BASE_DIR..."
log_info ""

# Verify base dir exists (should be the mounted secondary disk)
if [ ! -d "$BASE_DIR" ]; then
    log_error "$BASE_DIR does not exist. Is the secondary disk mounted?"
    log_error "Check: df -h $BASE_DIR"
    exit 1
fi

# Docker data directories (configs)
log_info "Creating docker-data directories..."
mkdir -p "$BASE_DIR/docker-data/plex"
mkdir -p "$BASE_DIR/docker-data/jellyfin"
mkdir -p "$BASE_DIR/docker-data/radarr"
mkdir -p "$BASE_DIR/docker-data/sonarr"
mkdir -p "$BASE_DIR/docker-data/lidarr"
mkdir -p "$BASE_DIR/docker-data/arcane"

# Media directories
log_info "Creating media directories..."
mkdir -p "$BASE_DIR/films"
mkdir -p "$BASE_DIR/series"
mkdir -p "$BASE_DIR/music"

# Permissions
log_info "Setting permissions (755)..."
chmod 755 "$BASE_DIR/docker-data"
chmod 755 "$BASE_DIR/docker-data/plex"
chmod 755 "$BASE_DIR/docker-data/jellyfin"
chmod 755 "$BASE_DIR/docker-data/radarr"
chmod 755 "$BASE_DIR/docker-data/sonarr"
chmod 755 "$BASE_DIR/docker-data/lidarr"
chmod 755 "$BASE_DIR/docker-data/arcane"
chmod 755 "$BASE_DIR/films"
chmod 755 "$BASE_DIR/series"
chmod 755 "$BASE_DIR/music"

log_info ""
log_info "Directory structure created ✓"
log_info ""
log_info "Structure:"
tree -L 2 "$BASE_DIR" 2>/dev/null || find "$BASE_DIR" -type d | sort

log_info ""
log_info "Next steps:"
log_info "1. Verify .env has:"
log_info "   MEDIA_STORAGE_PATH=$BASE_DIR"
log_info ""
log_info "2. Start containers:"
log_info "   docker compose up -d"
log_info ""
