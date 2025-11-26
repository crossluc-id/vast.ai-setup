#!/bin/bash
# ============================================================
# VAST.AI ENVIRONMENT AUDIT SCRIPT
# Captures complete state of ComfyUI installation
# ============================================================

AUDIT_DIR="/workspace/environment_audit_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$AUDIT_DIR"

echo "=========================================="
echo "VAST.AI ENVIRONMENT AUDIT"
echo "Output directory: $AUDIT_DIR"
echo "=========================================="

# ============================================================
# 1. SYSTEM INFO
# ============================================================
echo "Capturing system info..."
cat > "$AUDIT_DIR/01_system_info.txt" << EOF
=== SYSTEM INFO ===
Date: $(date)
Hostname: $(hostname)
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Kernel: $(uname -r)
GPU: $(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo "N/A")
CUDA Version: $(nvidia-smi | grep "CUDA Version" | awk '{print $9}' 2>/dev/null || echo "N/A")
Python: $(python --version 2>&1)
Pip: $(pip --version 2>&1)
EOF

# ============================================================
# 2. PYTHON PACKAGES (Full list with versions)
# ============================================================
echo "Capturing Python packages..."
pip list --format=freeze > "$AUDIT_DIR/02_python_packages_freeze.txt"
pip list > "$AUDIT_DIR/02_python_packages_readable.txt"

# Key packages summary
cat > "$AUDIT_DIR/02_key_packages.txt" << EOF
=== KEY PACKAGES ===
$(pip show torch torchvision torchaudio xformers triton sageattention 2>/dev/null | grep -E "^(Name|Version):" | paste - -)
EOF

# ============================================================
# 3. COMFYUI CUSTOM NODES
# ============================================================
echo "Capturing custom nodes..."
COMFY_NODES="/workspace/ComfyUI/custom_nodes"

if [ -d "$COMFY_NODES" ]; then
    echo "=== CUSTOM NODES ===" > "$AUDIT_DIR/03_custom_nodes.txt"
    echo "" >> "$AUDIT_DIR/03_custom_nodes.txt"
    
    for node_dir in "$COMFY_NODES"/*/; do
        if [ -d "$node_dir" ]; then
            node_name=$(basename "$node_dir")
            echo "--- $node_name ---" >> "$AUDIT_DIR/03_custom_nodes.txt"
            
            # Get git remote URL if it's a git repo
            if [ -d "$node_dir/.git" ]; then
                git_url=$(cd "$node_dir" && git remote get-url origin 2>/dev/null || echo "No remote")
                git_branch=$(cd "$node_dir" && git branch --show-current 2>/dev/null || echo "N/A")
                git_commit=$(cd "$node_dir" && git rev-parse HEAD 2>/dev/null || echo "N/A")
                echo "  URL: $git_url" >> "$AUDIT_DIR/03_custom_nodes.txt"
                echo "  Branch: $git_branch" >> "$AUDIT_DIR/03_custom_nodes.txt"
                echo "  Commit: $git_commit" >> "$AUDIT_DIR/03_custom_nodes.txt"
            else
                echo "  (Not a git repository)" >> "$AUDIT_DIR/03_custom_nodes.txt"
            fi
            echo "" >> "$AUDIT_DIR/03_custom_nodes.txt"
        fi
    done
    
    # Simple list for provisioning script
    echo "=== CLONE COMMANDS ===" > "$AUDIT_DIR/03_custom_nodes_clone_commands.txt"
    for node_dir in "$COMFY_NODES"/*/; do
        if [ -d "$node_dir/.git" ]; then
            node_name=$(basename "$node_dir")
            git_url=$(cd "$node_dir" && git remote get-url origin 2>/dev/null)
            if [ -n "$git_url" ]; then
                echo "git clone $git_url" >> "$AUDIT_DIR/03_custom_nodes_clone_commands.txt"
            fi
        fi
    done
fi

# ============================================================
# 4. MODELS INVENTORY
# ============================================================
echo "Capturing models..."
MODELS_DIR="/workspace/ComfyUI/models"

if [ -d "$MODELS_DIR" ]; then
    echo "=== MODELS INVENTORY ===" > "$AUDIT_DIR/04_models_inventory.txt"
    echo "Generated: $(date)" >> "$AUDIT_DIR/04_models_inventory.txt"
    echo "" >> "$AUDIT_DIR/04_models_inventory.txt"
    
    # Find all model files with sizes
    find "$MODELS_DIR" -type f \( -name "*.safetensors" -o -name "*.ckpt" -o -name "*.pt" -o -name "*.pth" -o -name "*.bin" -o -name "*.onnx" \) -exec ls -lh {} \; 2>/dev/null | \
    awk '{print $5, $9}' | sort -k2 >> "$AUDIT_DIR/04_models_inventory.txt"
    
    # Organized by folder
    echo "" >> "$AUDIT_DIR/04_models_inventory.txt"
    echo "=== BY CATEGORY ===" >> "$AUDIT_DIR/04_models_inventory.txt"
    
    for subdir in "$MODELS_DIR"/*/; do
        if [ -d "$subdir" ]; then
            subdir_name=$(basename "$subdir")
            file_count=$(find "$subdir" -type f \( -name "*.safetensors" -o -name "*.ckpt" -o -name "*.pt" -o -name "*.pth" -o -name "*.bin" \) 2>/dev/null | wc -l)
            if [ "$file_count" -gt 0 ]; then
                echo "" >> "$AUDIT_DIR/04_models_inventory.txt"
                echo "[$subdir_name] ($file_count files)" >> "$AUDIT_DIR/04_models_inventory.txt"
                find "$subdir" -type f \( -name "*.safetensors" -o -name "*.ckpt" -o -name "*.pt" -o -name "*.pth" -o -name "*.bin" \) -exec basename {} \; 2>/dev/null | sort >> "$AUDIT_DIR/04_models_inventory.txt"
            fi
        fi
    done
fi

# ============================================================
# 5. CUSTOM NODE DEPENDENCIES (requirements.txt files)
# ============================================================
echo "Capturing node dependencies..."
echo "=== NODE REQUIREMENTS ===" > "$AUDIT_DIR/05_node_requirements.txt"

for node_dir in "$COMFY_NODES"/*/; do
    if [ -d "$node_dir" ]; then
        node_name=$(basename "$node_dir")
        if [ -f "$node_dir/requirements.txt" ]; then
            echo "" >> "$AUDIT_DIR/05_node_requirements.txt"
            echo "--- $node_name/requirements.txt ---" >> "$AUDIT_DIR/05_node_requirements.txt"
            cat "$node_dir/requirements.txt" >> "$AUDIT_DIR/05_node_requirements.txt"
        fi
    fi
done

# ============================================================
# 6. DISK USAGE
# ============================================================
echo "Capturing disk usage..."
cat > "$AUDIT_DIR/06_disk_usage.txt" << EOF
=== DISK USAGE ===

Overall:
$(df -h /workspace 2>/dev/null || df -h /)

ComfyUI Directory:
$(du -sh /workspace/ComfyUI 2>/dev/null || echo "N/A")

Models Breakdown:
$(du -sh /workspace/ComfyUI/models/*/ 2>/dev/null | sort -hr)

Custom Nodes:
$(du -sh /workspace/ComfyUI/custom_nodes 2>/dev/null || echo "N/A")
EOF

# ============================================================
# 7. ENVIRONMENT VARIABLES
# ============================================================
echo "Capturing environment variables..."
env | grep -E "^(CUDA|PYTHON|PATH|LD_|TORCH|HF_|COMFY)" | sort > "$AUDIT_DIR/07_environment_variables.txt"

# ============================================================
# 8. COMFYUI CONFIG
# ============================================================
echo "Capturing ComfyUI config..."
if [ -f "/workspace/ComfyUI/extra_model_paths.yaml" ]; then
    cp "/workspace/ComfyUI/extra_model_paths.yaml" "$AUDIT_DIR/08_extra_model_paths.yaml"
fi

if [ -f "/workspace/ComfyUI/config.yaml" ]; then
    cp "/workspace/ComfyUI/config.yaml" "$AUDIT_DIR/08_config.yaml"
fi

# ============================================================
# 9. GENERATE PROVISIONING SCRIPT TEMPLATE
# ============================================================
echo "Generating provisioning script template..."

cat > "$AUDIT_DIR/09_generated_provisioning.sh" << 'SCRIPT_HEADER'
#!/bin/bash
# ============================================================
# AUTO-GENERATED PROVISIONING SCRIPT
# Generated from environment audit
# ============================================================

set -e
cd /workspace

SCRIPT_HEADER

# Add Python packages section
echo "" >> "$AUDIT_DIR/09_generated_provisioning.sh"
echo "# ============================================================" >> "$AUDIT_DIR/09_generated_provisioning.sh"
echo "# PYTHON PACKAGES" >> "$AUDIT_DIR/09_generated_provisioning.sh"
echo "# ============================================================" >> "$AUDIT_DIR/09_generated_provisioning.sh"

# Extract key packages
for pkg in torch torchvision torchaudio xformers triton sageattention safetensors huggingface_hub accelerate transformers diffusers einops omegaconf imageio insightface onnxruntime-gpu; do
    version=$(pip show "$pkg" 2>/dev/null | grep "^Version:" | awk '{print $2}')
    if [ -n "$version" ]; then
        echo "# pip install ${pkg}==${version}" >> "$AUDIT_DIR/09_generated_provisioning.sh"
    fi
done

# Add custom nodes section
echo "" >> "$AUDIT_DIR/09_generated_provisioning.sh"
echo "# ============================================================" >> "$AUDIT_DIR/09_generated_provisioning.sh"
echo "# CUSTOM NODES" >> "$AUDIT_DIR/09_generated_provisioning.sh"
echo "# ============================================================" >> "$AUDIT_DIR/09_generated_provisioning.sh"
echo "cd /workspace/ComfyUI/custom_nodes" >> "$AUDIT_DIR/09_generated_provisioning.sh"
echo "" >> "$AUDIT_DIR/09_generated_provisioning.sh"

for node_dir in "$COMFY_NODES"/*/; do
    if [ -d "$node_dir/.git" ]; then
        git_url=$(cd "$node_dir" && git remote get-url origin 2>/dev/null)
        if [ -n "$git_url" ]; then
            echo "git clone $git_url" >> "$AUDIT_DIR/09_generated_provisioning.sh"
        fi
    fi
done

# ============================================================
# 10. CREATE SUMMARY
# ============================================================
echo "Creating summary..."

cat > "$AUDIT_DIR/00_SUMMARY.txt" << EOF
========================================
ENVIRONMENT AUDIT SUMMARY
========================================
Generated: $(date)

SYSTEM:
- GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
- CUDA: $(nvidia-smi | grep "CUDA Version" | awk '{print $9}' 2>/dev/null)
- Python: $(python --version 2>&1)

COUNTS:
- Python packages: $(pip list 2>/dev/null | wc -l)
- Custom nodes: $(ls -d "$COMFY_NODES"/*/ 2>/dev/null | wc -l)
- Model files: $(find "$MODELS_DIR" -type f \( -name "*.safetensors" -o -name "*.ckpt" -o -name "*.pt" -o -name "*.pth" \) 2>/dev/null | wc -l)

DISK USAGE:
$(du -sh /workspace/ComfyUI 2>/dev/null)

FILES IN THIS AUDIT:
$(ls -1 "$AUDIT_DIR")

========================================
EOF

# ============================================================
# DONE
# ============================================================
echo ""
echo "=========================================="
echo "AUDIT COMPLETE!"
echo "=========================================="
echo ""
echo "Output saved to: $AUDIT_DIR"
echo ""
echo "Key files:"
echo "  00_SUMMARY.txt              - Quick overview"
echo "  02_python_packages_freeze.txt - pip freeze output (for requirements.txt)"
echo "  03_custom_nodes.txt         - All nodes with git URLs and commits"
echo "  03_custom_nodes_clone_commands.txt - Ready-to-use git clone commands"
echo "  04_models_inventory.txt     - All model files with sizes"
echo "  09_generated_provisioning.sh - Auto-generated provisioning template"
echo ""
echo "To download this audit:"
echo "  tar -czvf environment_audit.tar.gz $AUDIT_DIR"
echo ""