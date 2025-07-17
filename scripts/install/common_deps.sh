set -euo pipefail

log_step() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - common_deps.sh: $1"
}

log_step "Updating package list and upgrading existing packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

log_step "Installing essential common dependencies..."
sudo apt-get install -y \
	micro \
	ranger\
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    lsb-release

log_step "Cleaning up unnecessary packages..."
sudo apt-get autoremove -y
sudo apt-get clean

log_step "Common dependencies installation complete."
