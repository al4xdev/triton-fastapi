#!/bin/bash
set -euo pipefail

log_step() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - docker.sh: $1"
}

log_step "Installing Docker Engine..."

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg


sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D 
echo deb https://apt.dockerproject.org/repo ubuntu-trusty main | sudo tee /etc/apt/sources.list.d/docker.list 
sudo apt-get update 
sudo apt-get -y install docker-engine=1.12.6-0~ubuntu-trusty


wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb

log_step "Adding current user to 'docker' group to run Docker without sudo..."
sudo usermod -aG docker "$USER"

log_step "Docker Engine installed. Proceeding with NVIDIA Container Toolkit."

log_step "Installing NVIDIA Container Toolkit..."

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
         sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
         sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit

log_step "Configuring Docker daemon to use NVIDIA runtime..."
sudo nvidia-ctk runtime configure --runtime=docker

log_step "Restarting Docker service to apply changes..."
sudo systemctl restart docker

log_step "Docker and NVIDIA Container Toolkit installation complete."
log_step "REMINDER: You need to log out and log back in (or reboot) for the 'docker' group changes to take effect."