#!/bin/bash


set -euo pipefail

log_step() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - python.sh: $1"
}

MIDDLEWARE_DIR="$HOME/git/triton-fastapi/middleware/src"
MIDDLEWARE_VENV_DIR="$MIDDLEWARE_DIR/.venv"
UV_INSTALL_PATH="$HOME/.local/bin" # Onde o 'uv' é instalado por padrão
BASHRC_FILE="$HOME/.bashrc"
LINE_TO_ADD='source $HOME/.local/bin/env'

log_step "Iniciando a configuração do ambiente Python."

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

log_step "Verificando e adicionando a linha 'uv' ao .bashrc..."
if ! grep -qxF "$LINE_TO_ADD" "$BASHRC_FILE"; then
  log_step "Adicionando '$LINE_TO_ADD' a $BASHRC_FILE..."
  echo "$LINE_TO_ADD" | tee -a "$BASHRC_FILE" > /dev/null
  log_step "Linha adicionada com sucesso ao .bashrc."
else
  log_step "A linha já está presente em $BASHRC_FILE. Nenhuma alteração feita."
fi


log_step "Verificando instalação do Python 3 e headers de desenvolvimento..."

if ! command -v python3.11 &> /dev/null; then
    log_step "AVISO: Python 3.11 não encontrado. Assegure-se de que ele esteja disponível no ambiente ou instale-o manualmente."
else
    log_step "Python 3.11 encontrado."
fi


# --- Instalação do uv ---
log_step "Instalando uv (Python package installer e manager)..."
if ! command -v uv &> /dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  log_step "uv instalado com sucesso."
else
  log_step "uv já está instalado. Pulando a instalação."
fi


source "$UV_INSTALL_PATH/env" || true

if command -v uv &> /dev/null; then
  log_step "uv disponível. Versão: $(uv --version)"
else
  log_step "ERRO: A instalação do uv falhou ou não está no PATH. Verifique a instalação."
  exit 1
fi

log_step "Criando ambiente virtual Python para o middleware usando uv..."
uv venv --python 3.11 "$MIDDLEWARE_VENV_DIR"

if [ -d "$MIDDLEWARE_VENV_DIR" ]; then
  log_step "Ambiente virtual criado em: $MIDDLEWARE_VENV_DIR"
else
  log_step "ERRO: Falha ao criar ambiente virtual para o middleware em $MIDDLEWARE_VENV_DIR."
  exit 1
fi

log_step "Ativando ambiente virtual e instalando dependências do middleware..."
source "$MIDDLEWARE_VENV_DIR/bin/activate"

log_step "Instalando dependências de middleware/pyproject.toml e uv.lock..."
if uv sync --project "$MIDDLEWARE_DIR/pyproject.toml"; then
  log_step "Dependências do middleware instaladas com sucesso."
else
  log_step "ERRO: Falha ao instalar dependências do middleware usando uv sync."
  deactivate
  exit 1
fi

deactivate

log_step "Configuração do ambiente Python concluída com sucesso."
echo "Para que as alterações no seu .bashrc entrem em vigor, por favor, abra um novo terminal"