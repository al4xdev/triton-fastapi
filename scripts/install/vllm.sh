#!/bin/bash
set -euo pipefail

log_step() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - vllm.sh: $1"
}

# Caminhos relativos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
VLLM_DIR="$PROJECT_ROOT/vllm"

log_step "Entrando no diretório da fork VLLM: $VLLM_DIR"
cd "$VLLM_DIR"

log_step "Buildando imagem Docker personalizada..."
docker build -t vllm-custom .

log_step "✅ Build concluído com sucesso!"
