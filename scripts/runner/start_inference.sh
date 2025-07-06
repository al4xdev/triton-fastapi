#!/bin/bash

echo "Starting vLLM Inference Server..."

# Example command to start the vLLM API server.
# You will need to specify your model and potentially other settings.
# For example: --model tiiuae/falcon-7b-instruct --tensor-parallel-size 1
python -m vllm.entrypoints.api_server --host 0.0.0.0 --port 8000 --model YOUR_MODEL_NAME --dtype auto