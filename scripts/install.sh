#!/bin/bash
set -euo pipefail

INSTALL_DIR="$(dirname "$0")/install"
LOG_DIR="../logs"
INSTALL_FLAG_FILE="../.installed"
mkdir -p "$LOG_DIR"

check_installation() {
    if [ -f "$INSTALL_FLAG_FILE" ]; then
        echo "=== SYSTEM ALREADY INSTALLED ==="
        echo "Found: $INSTALL_FLAG_FILE"
        echo "Skipping installation..."
        return 0
    fi
    return 1
}

main() {
    if check_installation; then
        exit 0
    fi

    echo "=== STARTING INSTALLATION ==="
    echo "Timestamp: $(date)"

    echo "=== INSTALLING SYSTEM DEPS ==="
    bash "$INSTALL_DIR/common_deps.sh" >> "$LOG_DIR/install.log" 2>&1

    echo "=== SETTING UP PYTHON ==="
    bash "$INSTALL_DIR/python.sh" >> "$LOG_DIR/install.log" 2>&1

    echo "=== INSTALLING UV ==="
    bash "$INSTALL_DIR/uv.sh" >> "$LOG_DIR/install.log" 2>&1

    echo "=== INSTALLING DOCKER ==="
    bash "$INSTALL_DIR/docker.sh" >> "$LOG_DIR/install.log" 2>&1

    echo "=== INSTALLING NVIDIA DRIVERS ==="
    bash "$INSTALL_DIR/nvidia.sh" >> "$LOG_DIR/install.log" 2>&1

    echo "=== INSTALLING TRITON ==="
    bash "$INSTALL_DIR/triton.sh" >> "$LOG_DIR/install.log" 2>&1

    echo "=== VALIDATING ENVIRONMENT ==="
    bash "$INSTALL_DIR/validate_env.sh" >> "$LOG_DIR/install.log" 2>&1

    touch "$INSTALL_FLAG_FILE"
    echo "=== INSTALLATION COMPLETE ==="
    echo "Total time: $SECONDS seconds"
    echo "Details logged to: $LOG_DIR/install.log"
}

SECONDS=0
main "$@"
