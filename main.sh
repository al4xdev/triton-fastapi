## just commands for save

sudo usermod -aG docker $USER && newgrp docker

sudo systemctl enable --now docker

docker pull vllm/vllm-openai:latest # Use a generic vLLM OpenAI image
# Or build your own vLLM image if required


# model
graph TB
    A[Baixar Phi-14B FP16] --> B[Converter para INT8]
    B --> C[Adicionar Tensor flash attencion e Parallelism se necessário]
    C --> D[Deploy no Triton]
    D --> E[Monitorar VRAM via NVIDIA-SMI]
# model

docker run --rm -p 8000:8000 -p 8001:8001 -p 8002:8002 \
    vllm/vllm-openai:latest \
    python -m vllm.entrypoints.api_server --host 0.0.0.0 --port 8000 --model YOUR_MODEL_NAME --download-dir /models # Example vLLM command
    # Replace YOUR_MODEL_NAME with the actual model you want to serve



