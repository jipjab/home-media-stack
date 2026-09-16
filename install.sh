#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Ubuntu version
log_info "Checking Ubuntu version..."
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_MAJOR=$(echo $UBUNTU_VERSION | cut -d. -f1)

if [ "$UBUNTU_MAJOR" -lt 22 ]; then
    log_error "Ubuntu 22.04 LTS or later required. Current: $UBUNTU_VERSION"
    exit 1
fi
log_info "Ubuntu version: $UBUNTU_VERSION ✓"

# Update system
log_info "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
log_info "Installing dependencies..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    jq

# Add Docker GPG key
log_info "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
log_info "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update packages
sudo apt-get update

# Install Docker Engine
log_info "Installing Docker Engine..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
log_info "Configuring Docker permissions for current user..."
sudo usermod -aG docker $USER
log_warn "User added to docker group. You may need to log out/in or run: newgrp docker"

# Verify Docker installation
log_info "Verifying Docker installation..."
DOCKER_VERSION=$(docker --version)
log_info "Docker: $DOCKER_VERSION ✓"

# Verify Docker Compose
COMPOSE_VERSION=$(docker compose version)
log_info "Docker Compose: $COMPOSE_VERSION ✓"

# Test Docker daemon
log_info "Testing Docker daemon..."
docker run --rm hello-world > /dev/null 2>&1 && log_info "Docker daemon working ✓" || log_error "Docker daemon test failed"

log_info ""
log_info "=========================================="
log_info "Docker installation complete!"
log_info "=========================================="
log_info ""
log_info "Next steps:"
log_info "1. If secondary disk not yet setup, run:"
log_info "   bash scripts/setup-directories.sh"
log_info ""
log_info "2. Copy .env.example to .env and fill in your values:"
log_info "   cp .env.example .env"
log_info ""
log_info "3. Start containers:"
log_info "   docker compose up -d"
log_info ""
log_info "4. Access services:"
log_info "   - Plex: http://localhost:32400"
log_info "   - Jellyfin: http://localhost:8096 (HTTPS: 8920)"
log_info "   - Radarr: http://localhost:7878"
log_info "   - Sonarr: http://localhost:8989"
log_info "   - Lidarr: http://localhost:8686"
log_info "   - Arcane: managed via Arcane control plane (agent already installed)"
log_info ""
