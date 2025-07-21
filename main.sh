#!/bin/bash

INSTALL_SCRIPT="scripts/install.sh"

if [ -f "$INSTALL_SCRIPT" ]; then
    echo "Iniciando a instalação via $INSTALL_SCRIPT..."
    bash "$INSTALL_SCRIPT"
else
    echo "ERRO: O script de instalação '$INSTALL_SCRIPT' não foi encontrado."
    echo "Certifique-se de que a estrutura de diretórios está correta."
    exit 1
fi