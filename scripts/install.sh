#!/bin/bash
set -euo pipefail

# --- Configuration Variables ---
INSTALL_DIR="$(dirname "$0")/install"
LOG_DIR="../logs"
INSTALL_FLAG_FILE="../.installed"
INSTALL_STATE_FILE="../.install_state"
touch "$INSTALL_STATE_FILE" 
exec 6<> "$INSTALL_STATE_FILE"

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
        (
            flock 6 # Bloqueia para leitura
            cat "$INSTALL_STATE_FILE"
        ) 6< "$INSTALL_STATE_FILE" # Abre descritor de arquivo 6 para leitura
    else
        echo "START"
    fi
}

save_install_state() {
    local new_state="$1"
    (
        flock 6 # Bloqueia para escrita
        echo "$new_state" > "$INSTALL_STATE_FILE"
    ) 6> "$INSTALL_STATE_FILE" || { # Abre descritor de arquivo 6 para escrita
        log_message "FATAL ERROR: Failed to write state '$new_state' to $INSTALL_STATE_FILE. Check disk space or other system issues."
        exit 1
    }
    log_message "Installation state saved: $new_state"
    log_message "DEBUG: save_install_state called from $(caller 0)" # CRUCIAL para depuração!
    log_message "DEBUG: Conteúdo atual de $INSTALL_STATE_FILE: $(cat "$INSTALL_STATE_FILE")" # CRUCIAL para depuração!
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

declare -A STEPS
STEPS["START"]="common_deps.sh"
STEPS["COMMON_DEPS_DONE"]="python.sh"
STEPS["PYTHON_DONE"]="nvidia.sh"
STEPS["NVIDIA_DONE"]="docker.sh"
STEPS["DOCKER_DONE"]="validate_env.sh"
STEPS["VALIDATION_DONE"]="FINISH"

declare -a STATE_ORDER=(
    "START"
    "COMMON_DEPS_DONE"
    "PYTHON_DONE"
    "NVIDIA_DONE"
    "DOCKER_DONE"
    "VALIDATION_DONE"
    "FINISH"
)

execute_installation_sequence() {
    local CURRENT_STATE=$(get_install_state)
    log_message "Current installation state (Initial): $CURRENT_STATE"

    if [ "$CURRENT_STATE" = "REBOOTING_AFTER_NVIDIA" ]; then
        log_message "Resuming installation after reboot."
        disable_reboot_service
        CURRENT_STATE="NVIDIA_DONE"
        # Salva o estado atualizado imediatamente para refletir que o reboot foi tratado
        save_install_state "$CURRENT_STATE"
        log_message "Installation state reset to: $CURRENT_STATE"
    fi

    # --- Loop Principal de Instalação ---
    while true; do
        log_message "DEBUG: *** Início da Iteração do Loop ***"
        log_message "DEBUG: Estado atual lido para esta iteração: $CURRENT_STATE"

        if [ "$CURRENT_STATE" = "FINISH" ]; then
            log_message "All installation steps completed successfully."
            rm -f "$INSTALL_STATE_FILE"
            touch "$INSTALL_FLAG_FILE"
            log_message "=== INSTALLATION COMPLETE ==="
            log_message "Total time: $SECONDS seconds"
            log_message "Details logged to: $LOG_DIR/install.log"
            break # Sai do loop principal
        fi

        local script_to_run="${STEPS[$CURRENT_STATE]}"

        if [ -z "$script_to_run" ]; then
            log_message "ERROR: No script defined for state: $CURRENT_STATE. Aborting."
            exit 1
        fi
        log_message "DEBUG: Script a ser executado para '$CURRENT_STATE': $script_to_run"

        local next_state_to_save=""
        local current_state_index=-1

        # Encontra o índice do estado atual na lista ordenada
        for i in "${!STATE_ORDER[@]}"; do
            if [ "${STATE_ORDER[$i]}" = "$CURRENT_STATE" ]; then
                current_state_index="$i"
                break
            fi
        done

        if [ "$current_state_index" -eq -1 ]; then
            log_message "ERROR: Current state '$CURRENT_STATE' not found in STATE_ORDER. Aborting."
            exit 1
        fi

        # Calcula o índice do próximo estado
        local next_state_index=$((current_state_index + 1))

        # Verifica se há um próximo estado na lista
        if [ "$next_state_index" -lt "${#STATE_ORDER[@]}" ]; then
            next_state_to_save="${STATE_ORDER[$next_state_index]}"
        elif [ "$CURRENT_STATE" = "VALIDATION_DONE" ]; then # Caso especial para o último passo antes de FINISH
            next_state_to_save="FINISH" # Garante que o FINISH é o próximo estado
        else
            log_message "ERROR: Could not determine the next state after '$CURRENT_STATE' in STATE_ORDER. Aborting."
            exit 1
        fi

        log_message "DEBUG: Próximo estado determinado para salvar após este passo: $next_state_to_save"

        # Se o script atual não for "FINISH", precisa de um próximo estado válido
        if [ -z "$next_state_to_save" ] && [ "$script_to_run" != "FINISH" ]; then
            log_message "ERROR: Could not determine the next state after $CURRENT_STATE. Aborting."
            exit 1
        fi
        log_message "DEBUG: Próximo estado determinado para salvar após este passo: $next_state_to_save"

        # 4. Verifica se o passo atual é o da instalação do NVIDIA (que requer reboot)
        # Esta verificação deve ser feita *antes* de executar o script real.
        if [ "$script_to_run" = "nvidia.sh" ]; then
            log_message "NVIDIA drivers installation pending. Setting up reboot service."
            # Salva o estado para indicar que o reboot está pendente e o script reiniciará
            save_install_state "REBOOTING_AFTER_NVIDIA"
            setup_reboot_service # Esta função executará 'sudo reboot'
            exit 0 # O script terminará aqui e será reiniciado após o reboot pelo systemd service
        fi

        log_message "=== EXECUTING: $script_to_run ==="

        # 5. Executa o script do passo atual
        # Redireciona tanto stdout quanto stderr para o arquivo de log.
        # O '|| {' é para capturar falhas no comando Bash e reagir a elas.
        bash "$INSTALL_DIR/$script_to_run" >> "$LOG_DIR/install.log" 2>&1 || {
            log_message "ERROR: Script $script_to_run failed! Check $LOG_DIR/install.log for details."
            exit 1 # Sai do script se um passo falhar
        }
        log_message "Script $script_to_run completed successfully."

        # 6. Após a execução BEM-SUCEDIDA do script, salva o próximo estado
        # e atualiza a variável CURRENT_STATE para a próxima iteração do loop.
        save_install_state "$next_state_to_save"
        CURRENT_STATE="$next_state_to_save"
        log_message "DEBUG: CURRENT_STATE atualizado para a próxima iteração: $CURRENT_STATE"
        log_message "DEBUG: *** Fim da Iteração do Loop ***"
        echo # Adiciona uma linha em branco no log para melhor legibilidade
    done
}

execute_installation_sequence