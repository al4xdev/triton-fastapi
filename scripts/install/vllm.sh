#!/bin/bash
set -euo pipefail

log_step() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - vllm.sh: $1"
}
USER_HOME="/home/accenture"
BASHRC="$USER_HOME/.bashrc"
FISH_CONFIG="$USER_HOME/.config/fish/config.fish"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
VLLM_DIR="$PROJECT_ROOT/inference_server/vllm"

log_step "Entrando no diretório da fork VLLM: $VLLM_DIR"
cd "$VLLM_DIR"

log_step "Buildando imagem Docker personalizada..."
docker build -t vllm-custom .

add_alias_if_missing() {
  local file="$1"
  local alias_line="$2"

  if ! grep -Fxq "$alias_line" "$file" 2>/dev/null; then
    echo "$alias_line" >> "$file"
    log_step "Alias adicionado ao arquivo $file: $alias_line"
  else
    log_step "Alias já existe no arquivo $file, pulando: $alias_line"
  fi
}

add_alias_if_missing "$BASHRC" "alias start_inference='docker run -p 8000:8000 --rm --gpus all --shm-size 10.24gb -v /home/accenture/git/triton-fastapi/inference_server/models:/app/models vllm-custom:latest'"
add_alias_if_missing "$BASHRC" "alias start_inference_bg='docker run -d -p 8000:8000 --rm --gpus all --shm-size 10.24gb -v /home/accenture/git/triton-fastapi/inference_server/models:/app/models vllm-custom:latest'"

add_alias_if_missing "$FISH_CONFIG" "alias start_inference 'docker run -p 8000:8000 --rm --gpus all --shm-size 10.24gb -v /home/accenture/git/triton-fastapi/inference_server/models:/app/models vllm-custom:latest'"
add_alias_if_missing "$FISH_CONFIG" "alias start_inference_bg 'docker run -d -p 8000:8000 --rm --gpus all --shm-size 10.24gb -v /home/accenture/git/triton-fastapi/inference_server/models:/app/models vllm-custom:latest'"


log_step "✅ Build DO VLLM concluído com sucesso!"
