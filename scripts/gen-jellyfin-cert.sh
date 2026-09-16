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
    log_error ".env not found"
    exit 1
fi

export $(grep -v '^#' .env | grep '^MEDIA_STORAGE_PATH' | xargs)

MEDIA_STORAGE_PATH="${MEDIA_STORAGE_PATH:?MEDIA_STORAGE_PATH not set}"
JELLYFIN_CONFIG="$MEDIA_STORAGE_PATH/docker-data/jellyfin"
CERT_PATH="$JELLYFIN_CONFIG/cert.crt"
KEY_PATH="$JELLYFIN_CONFIG/key.key"

log_info "Jellyfin Self-Signed Certificate Generator"
log_info "Config path: $JELLYFIN_CONFIG"
log_info ""

# Create directory if not exists
mkdir -p "$JELLYFIN_CONFIG"

# Check if certificate already exists
if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    # Check expiration
    EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_PATH" 2>/dev/null | cut -d= -f2)
    EXPIRY_DATE=$(date -d "$EXPIRY" +%s 2>/dev/null || echo 0)
    NOW=$(date +%s)
    DAYS_UNTIL=$(( ($EXPIRY_DATE - $NOW) / 86400 ))
    
    if [ $DAYS_UNTIL -gt 0 ]; then
        log_warn "Certificate already exists"
        log_info "  Expires in: $DAYS_UNTIL days ($EXPIRY)"
        log_info "  To regenerate, delete:"
        log_info "    rm $CERT_PATH $KEY_PATH"
        log_info "  Then rerun this script"
        exit 0
    else
        log_warn "Certificate expired. Regenerating..."
    fi
fi

# Generate self-signed certificate (365 days validity)
log_info "Generating self-signed certificate (365 days)..."

openssl req -new -x509 -days 365 -nodes \
    -out "$CERT_PATH" \
    -keyout "$KEY_PATH" \
    -subj "/CN=localhost/O=Home Media Stack/C=CH" \
    2>/dev/null

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    log_info "Certificate generated ✓"
    log_info "  Cert: $CERT_PATH"
    log_info "  Key:  $KEY_PATH"
    
    # Set permissions
    chmod 644 "$CERT_PATH"
    chmod 600 "$KEY_PATH"
    
    # Show expiration
    EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_PATH" | cut -d= -f2)
    log_info "  Expires: $EXPIRY"
    log_info ""
    log_info "Next steps:"
    log_info "1. Restart Jellyfin container:"
    log_info "   docker restart jellyfin"
    log_info ""
    log_info "2. Access HTTPS:"
    log_info "   https://localhost:8920"
    log_info ""
    log_info "3. Browser will warn about cert (normal, auto-signed)"
    log_info "   Click Advanced → Proceed"
else
    log_error "Failed to generate certificate"
    exit 1
fi
