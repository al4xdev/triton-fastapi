#!/bin/bash
set -euo pipefail
RECOMMENDED_DRIVER=$(ubuntu-drivers devices | grep -P '(?<=driver : )nvidia-\d+' | sort -r | head -n 1)

log_step() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - validate_env.sh: $1"
}

if [ -z "$RECOMMENDED_DRIVER" ]; then
    log_step "WARNING: Could not find a recommended NVIDIA driver. Attempting to install 'nvidia-driver-535' as a fallback. Check your GPU compatibility."
    RECOMMENDED_DRIVER="nvidia-driver-535" 
fi

log_step "Installing driver: $RECOMMENDED_DRIVER"
sudo apt-get install -y "$RECOMMENDED_DRIVER"

log_step "Installing NVIDIA display and management utilities..."
sudo apt-get install -y nvidia-utils-$(echo "$RECOMMENDED_DRIVER" | grep -oP '\d+') # Ex: nvidia-utils-535

log_step "NVIDIA validation complete."

log_step "Starting NVIDIA GPU driver installation via APT..."

log_step "Adding graphics-drivers PPA for up-to-date NVIDIA drivers..."
sudo add-apt-repository ppa:graphics-drivers/ppa -y

log_step "Updating package list after adding graphics-drivers PPA..."
sudo apt-get update -y

log_step "Identifying and installing the recommended NVIDIA driver..."

log_step "Verifying NVIDIA driver installation..."

if command -v nvidia-smi &> /dev/null; then
    log_step "nvidia-smi found. Displaying GPU status:"
    nvidia-smi
else
    log_step "ERROR: nvidia-smi not found after installation. Driver installation might have failed."
    exit 1
fi

log_step "NVIDIA GPU driver installation complete."
log_step "NOTE: A reboot might be required for the driver to be fully loaded, especially if this is the first driver installation."

log_step "Validating NVIDIA GPU and Docker integration..."

if command -v nvidia-smi &> /dev/null; then
    log_step "nvidia-smi found. Displaying GPU status on host:"
    nvidia-smi | tee -a "$LOG_FILE" # Redireciona para o log principal também
else
    log_step "WARNING: nvidia-smi not found on host. Drivers might not be fully installed or configured."
fi