# --- Main Installation Logic ---

SECONDS=0

if check_full_installation; then
    exit 0
fi

declare -A STEPS
STEPS["START"]="common_deps.sh"
STEPS["COMMON_DEPS_DONE"]="python.sh"
STEPS["UV_DONE"]="nvidia.sh"
STEPS["NVIDIA_DONE"]="docker.sh"
STEPS["DOCKER_DONE"]="validate_env.sh"
STEPS["VALIDATION_DONE"]="FINISH"

execute_installation_sequence() {
    local CURRENT_STATE=$(get_install_state)
    log_message "Current installation state: $CURRENT_STATE"

    # Handle resume after reboot
    if [ "$CURRENT_STATE" = "REBOOTING_AFTER_NVIDIA" ]; then
        log_message "Resuming installation after reboot."
        disable_reboot_service
        CURRENT_STATE="NVIDIA_DONE" # Move to the next logical step after reboot
        save_install_state "$CURRENT_STATE" # Save updated state
        log_message "Installation state reset to: $CURRENT_STATE"
    fi

    # Loop through installation steps
    while true; do
        if [ "$CURRENT_STATE" = "FINISH" ]; then
            log_message "All installation steps completed successfully."
            rm -f "$INSTALL_STATE_FILE"
            touch "$INSTALL_FLAG_FILE"
            log_message "=== INSTALLATION COMPLETE ==="
            log_message "Total time: $SECONDS seconds"
            log_message "Details logged to: $LOG_DIR/install.log"
            break # Exit the loop
        fi

        local script_to_run="${STEPS[$CURRENT_STATE]}"

        if [ -z "$script_to_run" ]; then
            log_message "ERROR: No script defined for state: $CURRENT_STATE. Aborting."
            exit 1
        fi

        # Check for NVIDIA step, which requires a reboot
        if [ "$CURRENT_STATE" = "UV_DONE" ]; then # This state leads to nvidia.sh
            log_message "NVIDIA drivers installation pending. Setting up reboot service."
            save_install_state "REBOOTING_AFTER_NVIDIA"
            setup_reboot_service
            exit 0 # Exit here, script will restart after reboot
        fi

        log_message "=== EXECUTING: $script_to_run ==="

        # Execute the script
        sudo -E bash "$INSTALL_DIR/$script_to_run" >> "$LOG_DIR/install.log" 2>&1 || {
            log_message "ERROR: Script $script_to_run failed!"
            exit 1
        }

        # Determine the next state based on the current state in the STEPS array
        local next_state=""
        local found_current=false
        for key in "${!STEPS[@]}"; do
            if [ "$found_current" ]; then
                next_state="$key"
                break
            fi
            if [ "$key" = "$CURRENT_STATE" ]; then
                found_current=true
            fi
        done

        if [ -z "$next_state" ]; then
            log_message "ERROR: Could not determine the next state after $CURRENT_STATE. Aborting."
            exit 1
        fi

        save_install_state "$next_state"
        CURRENT_STATE="$next_state" # Update CURRENT_STATE for the next iteration
    done
}

execute_installation_sequence