#!/bin/bash

set -euo pipefail

log_step() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - python.sh: $1"
}

MIDDLEWARE_DIR="/middleware/src"
MIDDLEWARE_VENV_DIR="$MIDDLEWARE_DIR/.venv"
LINE_TO_ADD='source $HOME/.local/bin/env'

ORIGINAL_USER_HOME=""
BASHRC_FILE=""

if [ -n "$SUDO_USER" ]; then
    ORIGINAL_USER_HOME=$(eval echo "~$SUDO_USER")
    BASHRC_FILE="$ORIGINAL_USER_HOME/.bashrc"
    echo "Executando como root. O .bashrc alvo é do usuário '$SUDO_USER': $BASHRC_FILE"
else
    ORIGINAL_USER_HOME="$HOME"
    BASHRC_FILE="$HOME/.bashrc"
    echo "Executando como usuário atual. O .bashrc alvo é: $BASHRC_FILE"
fi

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

log_step "Verificando e adicionando a linha 'uv' ao .bashrc do usuário original..."
if ! grep -qxF "$LINE_TO_ADD" "$BASHRC_FILE"; then
    echo "Adicionando '$LINE_TO_ADD' a $BASHRC_FILE..."
    echo "$LINE_TO_ADD" | sudo -u "$SUDO_USER" tee -a "$BASHRC_FILE" > /dev/null
    echo "Linha adicionada com sucesso ao .bashrc de $SUDO_USER!"
else
    echo "A linha já está presente em $BASHRC_FILE. Nenhuma alteração feita."
fi

log_step "Instalando Python 3 e headers de desenvolvimento..."
sudo apt-get update
sudo apt-get install -y python3 python3-dev

log_step "Instalando uv (Python package installer e manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh

source "$HOME/.local/bin/env"

if command -v uv &> /dev/null; then
    log_step "uv instalado com sucesso para o ambiente root. Versão: $(uv --version)"
else
    log_step "ERRO: A instalação do uv falhou. Verifique a conexão com a internet ou as permissões."
    exit 1
fi

log_step "Criando ambiente virtual Python para o middleware usando uv..."

uv venv --python 3.11 "$MIDDLEWARE_VENV_DIR"

if [ -d "$MIDDLEWARE_VENV_DIR" ]; then
    log_step "Ambiente virtual criado em: $MIDDLEWARE_VENV_DIR"
else
    log_step "ERRO: Falha ao criar ambiente virtual para o middleware."
    exit 1
fi

log_step "Ativando ambiente virtual e instalando dependências do middleware..."
source "$MIDDLEWARE_VENV_DIR/bin/activate"

log_step "Instalando dependências de middleware/pyproject.toml e uv.lock..."
if uv sync --project "$MIDDLEWARE_DIR/pyproject.toml"; then
    log_step "Dependências do middleware instaladas com sucesso."
else
    log_step "ERRO: Falha ao instalar dependências do middleware usando uv sync."
    exit 1
fi

deactivate

log_step "Configuração do ambiente Python concluída."
echo "Para que as alterações no seu .bashrc entrem em vigor, por favor, abra um novo terminal"
echo "ou execute 'source ~/.bashrc' na sua sessão atual."