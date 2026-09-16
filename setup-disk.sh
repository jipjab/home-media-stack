#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Configuration
DEVICE="/dev/sdb"
MOUNT_POINT="/home/media-stack"

log_info "======================================"
log_info "Setup Secondary Disk for Media Stack"
log_info "======================================"
log_info ""
log_info "Device: $DEVICE"
log_info "Mount point: $MOUNT_POINT"
log_info ""

# Safety checks
log_info "Running safety checks..."

# Check if device exists
if [ ! -b "$DEVICE" ]; then
    log_error "Device $DEVICE not found"
    exit 1
fi

# Check if already mounted
if grep -q "$DEVICE" /etc/mtab 2>/dev/null; then
    log_error "$DEVICE is already mounted"
    log_error "Unmount first: sudo umount $DEVICE*"
    exit 1
fi

# Check if mount point exists and is busy
if [ -d "$MOUNT_POINT" ]; then
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        log_error "$MOUNT_POINT is already a mount point"
        exit 1
    fi
    log_warn "$MOUNT_POINT already exists (will be used)"
fi

# Show current state
log_info ""
log_info "Current device state:"
lsblk "$DEVICE"
log_info ""

# Confirmation
read -p "Continue? (type 'yes' to proceed): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    log_info "Aborted"
    exit 0
fi

log_info ""
log_warn "⚠️  THIS WILL ERASE ALL DATA ON $DEVICE"
read -p "Confirm erase (type 'yes'): " CONFIRM2
if [ "$CONFIRM2" != "yes" ]; then
    log_info "Aborted"
    exit 0
fi

# Clear any existing partitions
log_info "Clearing existing partitions..."
sudo wipefs -af "$DEVICE" 2>/dev/null || true

# Create single partition (entire disk)
log_info "Creating partition..."
sudo parted -s "$DEVICE" mklabel gpt
sudo parted -s "$DEVICE" mkpart primary 0% 100%

# Wait for partition device
sleep 2
PARTITION="${DEVICE}1"

if [ ! -b "$PARTITION" ]; then
    log_error "Partition device $PARTITION not found after creation"
    exit 1
fi

log_info "Partition created: $PARTITION"

# Format to ext4
log_info "Formatting to ext4..."
sudo mkfs.ext4 -F "$PARTITION" > /dev/null 2>&1

log_info "Format complete ✓"

# Create mount point
if [ ! -d "$MOUNT_POINT" ]; then
    log_info "Creating mount point: $MOUNT_POINT"
    sudo mkdir -p "$MOUNT_POINT"
fi

# Mount
log_info "Mounting $PARTITION to $MOUNT_POINT..."
sudo mount "$PARTITION" "$MOUNT_POINT"

# Verify
if mountpoint -q "$MOUNT_POINT"; then
    log_info "Mount successful ✓"
    log_info ""
    log_info "Disk info:"
    df -h "$MOUNT_POINT"
else
    log_error "Mount failed"
    exit 1
fi

# Permissions
log_info "Setting permissions..."
sudo chown $USER:$USER "$MOUNT_POINT"
chmod 755 "$MOUNT_POINT"

# Make mount persistent (add to fstab)
log_info "Making mount persistent (fstab)..."
UUID=$(sudo blkid -s UUID -o value "$PARTITION")
if ! grep -q "$UUID" /etc/fstab; then
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab > /dev/null
    log_info "Added to /etc/fstab ✓"
else
    log_warn "UUID already in fstab"
fi

log_info ""
log_info "======================================"
log_info "✓ Disk setup complete!"
log_info "======================================"
log_info ""
log_info "Summary:"
log_info "  Device: $PARTITION"
log_info "  Mount: $MOUNT_POINT"
log_info "  UUID: $UUID"
log_info ""
log_info "Next: Clone project into $MOUNT_POINT"
