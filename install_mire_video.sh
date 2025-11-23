#!/bin/bash
set -e

echo "=============================================="
echo "  MIRE Video Workflow Installation"
echo "  Vast.ai Provisioning Script"
echo "=============================================="
echo ""

# Set workspace directory (vast.ai standard)
WORKSPACE=${WORKSPACE:-/workspace}
cd "$WORKSPACE"

# Check if using vast.ai base image with pre-activated venv
if [ -f "/venv/main/bin/activate" ]; then
    echo "Using vast.ai base image virtual environment..."
    source /venv/main/bin/activate
    COMFYUI_DIR="${WORKSPACE}/ComfyUI"
else
    echo "Creating new virtual environment..."
    COMFYUI_DIR="${WORKSPACE}/ComfyUI"
    if [ ! -d "${COMFYUI_DIR}/venv" ]; then
        python3 -m venv "${COMFYUI_DIR}/venv"
    fi
    source "${COMFYUI_DIR}/venv/bin/activate"
fi

# Clone ComfyUI if not exists
if [ ! -d "$COMFYUI_DIR" ]; then
    echo "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI "$COMFYUI_DIR"
fi

cd "$COMFYUI_DIR"

# Install base requirements
echo "Installing Python dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

# Install PyTorch with CUDA 12.1 support (if not already installed)
if ! python -c "import torch; print(torch.__version__)" 2>/dev/null; then
    echo "Installing PyTorch with CUDA 12.1..."
    pip uninstall torch torchvision torchaudio --yes --quiet
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 --quiet
fi

# Install essential packages
echo "Installing additional packages..."
pip install xformers==0.0.22 --quiet
pip install insightface --quiet
pip install onnxruntime-gpu --quiet

# Install git-lfs for large file downloads
if ! command -v git-lfs &> /dev/null; then
    echo "Installing git-lfs..."
    apt-get update -qq
    apt-get install -y git-lfs -qq
    git lfs install
fi

# Install ComfyUI Manager first (needed for other installations)
cd "$COMFYUI_DIR/custom_nodes"
if [ ! -d "ComfyUI-Manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager
fi

# Install custom nodes required for MIRE Video workflow
echo "Installing custom nodes..."

custom_nodes=(
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
    "https://github.com/banodoco/steerable-motion.git"
    "https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git"
    "https://github.com/Fannovel16/comfyui-advanced-controlnet.git"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    "https://github.com/cubiq/ComfyUI_essentials.git"
    "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git"
    "https://github.com/FizzleDorf/ComfyUI_FizzNodes.git"
    "https://github.com/BadCafeCode/masquerade-nodes-comfyui.git"
    "https://github.com/jags111/efficiency-nodes-comfyui.git"
    "https://github.com/spacepxl/ComfyUI-Dream-Project.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
)

for repo_url in "${custom_nodes[@]}"; do
    repo_name=$(basename "$repo_url" .git)
    node_path="${COMFYUI_DIR}/custom_nodes/${repo_name}"
    
    if [ -d "$node_path" ]; then
        if [ "${AUTO_UPDATE,,}" != "false" ]; then
            echo "Updating $repo_name..."
            (cd "$node_path" && git pull --quiet || true)
        else
            echo "✓ $repo_name already exists, skipping..."
            continue
        fi
    else
        echo "Cloning $repo_name..."
        git clone "$repo_url" "$node_path" --quiet
    fi
    
    # Install node-specific requirements if they exist
    if [ -f "$node_path/requirements.txt" ]; then
        echo "  Installing requirements for $repo_name..."
        pip install -r "$node_path/requirements.txt" --quiet --no-cache-dir
    fi
done

# Return to ComfyUI root
cd "$COMFYUI_DIR"

# Create necessary model directories
mkdir -p models/checkpoints
mkdir -p models/vae
mkdir -p models/ipadapter
mkdir -p models/clip_vision
mkdir -p models/animatediff_motion
mkdir -p models/animatediff_motion_lora
mkdir -p models/controlnet
mkdir -p models/loras
mkdir -p models/upscale_models
mkdir -p models/frame_interpolation

echo ""
echo "Custom nodes installation complete!"
echo ""

# Run the model download script
if [ -f "${WORKSPACE}/auto_download_models_mire.py" ]; then
    echo "Running model download script..."
    python3 "${WORKSPACE}/auto_download_models_mire.py"
elif [ -f "${COMFYUI_DIR}/auto_download_models_mire.py" ]; then
    echo "Running model download script..."
    python3 "${COMFYUI_DIR}/auto_download_models_mire.py"
else
    echo "Warning: auto_download_models_mire.py not found. Models will need to be downloaded manually."
fi

echo ""
echo "=============================================="
echo "  Installation Complete!"
echo "=============================================="
echo ""
echo "To start ComfyUI:"
if [ -f "/venv/main/bin/activate" ]; then
    echo "  source /venv/main/bin/activate"
else
    echo "  cd $COMFYUI_DIR && source venv/bin/activate"
fi
echo "  cd $COMFYUI_DIR"
echo "  python main.py --listen 0.0.0.0 --port 8188"
echo ""

