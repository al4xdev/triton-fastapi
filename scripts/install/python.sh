#!/bin/bash
set -euo pipefail

log_step() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - docker.sh: $1"
}

log_step "Installing Docker Engine..."

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log_step "Adding current user to 'docker' group to run Docker without sudo..."
sudo usermod -aG docker "$USER"

log_step "Docker Engine installed. Proceeding with NVIDIA Container Toolkit."

log_step "Installing NVIDIA Container Toolkit..."

log_step "Installing prerequisites for NVIDIA repository setup..."

sudo apt update

sudo apt install -y curl gnupg software-properties-common ca-certificates

log_step "Removing any existing NVIDIA Container Toolkit apt list file..."

sudo rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list

log_step "Adding NVIDIA GPG key..."

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

log_step "Downloading and processing NVIDIA Container Toolkit repository list..."

REPO_LIST_URL="https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list"

wget "$REPO_LIST_URL" -O /tmp/nvidia_container_raw.list

ARCH=$(dpkg --print-architecture)

log_step "Identified system architecture: $ARCH"

sudo sed -i "s#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g" /tmp/nvidia_container_raw.list

sudo sed -i "s#\$(ARCH)#$ARCH#g" /tmp/nvidia_container_raw.list

log_step "Moving processed repository list to apt sources directory..."

sudo cp /tmp/nvidia_container_raw.list /etc/apt/sources.list.d/nvidia-container-toolkit.list

log_step "Updating apt package lists..."

sudo apt update

log_step "Installing NVIDIA Container Toolkit..."

sudo apt install -y nvidia-container-toolkit

log_step "Configuring Docker daemon to use NVIDIA runtime..."
sudo nvidia-ctk runtime configure --runtime=docker

log_step "Restarting Docker service to apply changes..."
sudo systemctl restart docker

log_step "Docker and NVIDIA Container Toolkit installation complete."
log_step "REMINDER: You need to log out and log back in (or reboot) for the 'docker' group changes to take effect."
