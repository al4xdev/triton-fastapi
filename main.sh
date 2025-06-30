## just commands for save

sudo snap remove docker
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker $USER && newgrp docker

sudo systemctl enable --now docker

docker pull nvcr.io/nvidia/tritonserver:25.06-trtllm-python-py3


# model
graph TB
    A[Baixar Phi-14B FP16] --> B[Converter para INT8]
    B --> C[Adicionar Tensor flash attencion e Parallelism se necessário]
    C --> D[Deploy no Triton]
    D --> E[Monitorar VRAM via NVIDIA-SMI]
# model

docker run --rm -p 8000:8000 -p 8001:8001 -p 8002:8002 \
    -v $TRITON_FASTAPI_ROOT/inference_server/models:/models \
    nvcr.io/nvidia/tritonserver:23.07-py3 \
    tritonserver --model-repository=/models



