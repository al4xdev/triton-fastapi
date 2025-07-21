#!/bin/bash
set -euo pipefail

# --- Configuration Variables ---
INSTALL_DIR="$(dirname "$0")/install"
LOG_DIR="../logs"
INSTALL_FLAG_FILE="../.installed"
INSTALL_STATE_FILE="../.install_state"

# --- Setup Directories ---
mkdir -p "$LOG_DIR"

# --- Logging Function ---
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_DIR/install.log"
}

# --- Installation State Functions ---
check_full_installation() {
    if [ -f "$INSTALL_FLAG_FILE" ]; then
        log_message "=== SYSTEM ALREADY FULLY INSTALLED ==="
        log_message "Found: $INSTALL_FLAG_FILE"
        log_message "Skipping full installation..."
        return 0
    fi
    return 1
}

get_install_state() {
    if [ -f "$INSTALL_STATE_FILE" ]; then
        cat "$INSTALL_STATE_FILE"
    else
        echo "START"
    fi
}

save_install_state() {
    echo "$1" > "$INSTALL_STATE_FILE"
    log_message "Installation state saved: $1"
}

# --- Reboot Service Management ---
setup_reboot_service() {
    log_message "Configuring systemd service to resume installation after reboot..."

    local FULL_SCRIPT_PATH="$(realpath "$0")"

    mkdir -p "$HOME/.config/systemd/user"

    cat <<EOF > "$HOME/.config/systemd/user/resume-install.service"
[Unit]
Description=Resume ML Inference Server Installation
After=network-online.target

[Service]
Type=oneshot
ExecStart=$FULL_SCRIPT_PATH
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF
    systemctl --user enable resume-install.service
    log_message "systemd service 'resume-install.service' enabled."

    log_message "Rebooting in 5 seconds to load NVIDIA drivers and continue installation..."
    sleep 5
    sudo reboot
}

disable_reboot_service() {
    log_message "Disabling and removing systemd resume service..."
    systemctl --user disable resume-install.service
    rm -f "$HOME/.config/systemd/user/resume-install.service" # Use -f to suppress error if file doesn't exist
    systemctl --user daemon-reload
    systemctl --user reset-failed resume-install.service
}

# --- Main Installation Logic ---

SECONDS=0

if check_full_installation; then
    exit 0
fi

CURRENT_STATE=$(get_install_state)
log_message "Current installation state: $CURRENT_STATE"

declare -A STEPS
STEPS["START"]="common_deps.sh"
STEPS["COMMON_DEPS_DONE"]="python.sh"
STEPS["UV_DONE"]="nvidia.sh"
STEPS["NVIDIA_DONE"]="docker.sh"
STEPS["DOCKER_DONE"]="validate_env.sh"
STEPS["VALIDATION_DONE"]="FINISH"

execute_installation_sequence() {
    local start_processing=false
    local next_state=""

    for state in "${!STEPS[@]}"; do
        if [ "$state" = "$CURRENT_STATE" ]; then
            start_processing=true
        fi

        if "$start_processing"; then
            local script_to_run="${STEPS[$state]}"

            if [ "$state" = "NVIDIA_DONE" ]; then
                log_message "NVIDIA drivers installed. Setting up reboot service."
                save_install_state "REBOOTING_AFTER_NVIDIA"
                setup_reboot_service
                exit 0
            fi

            if [ "$CURRENT_STATE" = "REBOOTING_AFTER_NVIDIA" ] && [ "$state" = "NVIDIA_DONE" ]; then
                log_message "Resuming installation after reboot."
                disable_reboot_service
               
                CURRENT_STATE="NVIDIA_DONE"
            fi

            if [ "$script_to_run" = "FINISH" ]; then
                break
            fi

            log_message "=== EXECUTING: $script_to_run ==="
            bash "$INSTALL_DIR/$script_to_run" >> "$LOG_DIR/install.log" 2>&1

            local found_current_step=false
            for s in "${!STEPS[@]}"; do
                if [ "$found_current_step" ]; then
                    next_state="$s"
                    break
                fi
                if [ "$s" = "$state" ]; then
                    found_current_step=true
                fi
            done
            save_install_state "$next_state"
            CURRENT_STATE="$next_state"

        fi
    done

    if [ "$CURRENT_STATE" = "VALIDATION_DONE" ]; then
        log_message "All installation steps processed."
        rm -f "$INSTALL_STATE_FILE"
        touch "$INSTALL_FLAG_FILE"
        log_message "=== INSTALLATION COMPLETE ==="
        log_message "Total time: $SECONDS seconds"
        log_message "Details logged to: $LOG_DIR/install.log"
    else
        log_message "Installation sequence ended, but not all steps completed successfully or a reboot is pending."
    fi
}

execute_installation_sequenc