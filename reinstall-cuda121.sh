#!/bin/bash

# Reinstall PyTorch with CUDA 12.1
# Use this script to fix PyTorch/CUDA compatibility issues on existing containers

# Activate the virtual environment
source /venv/main/bin/activate

# Uninstall current torch packages
pip uninstall -y torch torchvision torchaudio xformers

# Install PyTorch 2.2.2 with CUDA 12.1
pip install --no-cache-dir \
    torch==2.2.2+cu121 \
    torchvision==0.17.2+cu121 \
    torchaudio==2.2.2+cu121 \
    --index-url https://download.pytorch.org/whl/cu121

# Install compatible xformers
pip install --no-cache-dir xformers==0.0.25.post1

# Verify installation
python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}')"

echo "Done! Restart ComfyUI now."

