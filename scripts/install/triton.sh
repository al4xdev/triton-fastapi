#!/bin/bash

log_step() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - triton.sh: $1"
}

log_message "Iniciando a instalação do NVIDIA Triton Inference Server..."

TRITON_IMAGE_NAME="nvcr.io/nvidia/tritonserver:23.07-py3"

log_message "Fazendo pull da imagem Docker do NVIDIA Triton Inference Server: $TRITON_IMAGE_NAME"

sudo docker pull "$TRITON_IMAGE_NAME" || {
    log_message "ERROR: Falha ao fazer pull da imagem do Triton Inference Server '$TRITON_IMAGE_NAME'."
    log_message "Verifique sua conexão com a internet e se o Docker está funcionando corretamente."
    exit 1
}

log_message "Imagem do NVIDIA Triton Inference Server '$TRITON_IMAGE_NAME' baixada com sucesso."

log_message "Instalação do NVIDIA Triton Inference Server concluída."