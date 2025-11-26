#!/bin/bash

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

# ============================================================================
# CONFIGURATION - Unified MIRE + WanVideo Workflow (Audit-based v2)
# ============================================================================

APT_PACKAGES=(
    "git-lfs"
    "ffmpeg"
)

PIP_PACKAGES=(
    "safetensors"
    "huggingface_hub"
    "insightface"
    "onnxruntime-gpu"
    "transformers"
    "accelerate"
    "diffusers"
    "einops"
    "omegaconf"
    "imageio"
    "imageio-ffmpeg"
)

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved"
    "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
    "https://github.com/Fannovel16/comfyui-advanced-controlnet"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/FizzleDorf/ComfyUI_FizzNodes"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/chrisgoringe/cg-use-everywhere"
    "https://github.com/alt-key-project/comfyui-dream-project"
    "https://github.com/jamesWalker55/comfyui-various"
    "https://github.com/jags111/efficiency-nodes-comfyui"
    "https://github.com/BadCafeCode/masquerade-nodes-comfyui"
    "https://github.com/banodoco/steerable-motion"
    "https://github.com/M1kep/ComfyLiterals"
    "https://github.com/Pirog17000/Pirogs-Nodes"
    "https://github.com/Stability-AI/stability-ComfyUI-nodes"
)

# ============================================================================
# LOCKED PACKAGE VERSIONS - reinstalled after node requirements
# ============================================================================
TORCH_VERSION="2.5.1+cu121"
TORCHVISION_VERSION="0.20.1+cu121"
TORCHAUDIO_VERSION="2.5.1+cu121"
XFORMERS_VERSION="0.0.28.post3"
TRITON_VERSION="3.1.0"
SAGEATTENTION_VERSION="2.2.0"

# ============================================================================
# MIRE WORKFLOW MODELS
# ============================================================================

CHECKPOINT_MODELS=(
    "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
    "https://huggingface.co/KamCastle/jugg/resolve/main/juggernaut_reborn.safetensors"
)

LORA_MODELS=(
    "https://huggingface.co/wangfuyun/AnimateLCM/resolve/main/AnimateLCM_sd15_t2v_lora.safetensors"
)

VAE_MODELS=(
    "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"
)

CONTROLNET_MODELS=(
    "https://huggingface.co/guoyww/animatediff/resolve/main/v3_sd15_sparsectrl_rgb.ckpt"
)

IPADAPTER_MODELS=(
    "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter-plus_sd15.safetensors"
)

CLIP_VISION_MODELS=(
    "https://huggingface.co/laion/CLIP-ViT-H-14-laion2B-s32B-b79K/resolve/main/open_clip_pytorch_model.safetensors"
)

ANIMATEDIFF_MODELS=(
    "https://huggingface.co/wangfuyun/AnimateLCM/resolve/main/AnimateLCM_sd15_t2v.ckpt"
)

ANIMATEDIFF_LORA_MODELS=(
    "https://huggingface.co/peteromallet/poms-funtime-mlora-emporium/resolve/main/LiquidAF-0-1.safetensors"
)

# ============================================================================
# WANVIDEO WORKFLOW MODELS (in diffusion_models/, text_encoders/, vae/)
# ============================================================================

DIFFUSION_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-T2V-14B_fp8_e4m3fn.safetensors"
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-VACE_module_14B_bf16.safetensors"
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VACE_1_3B_preview_bf16.safetensors"
)

TEXT_ENCODER_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp16.safetensors"
)

WANVIDEO_VAE_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors"
)

WANVIDEO_LORA_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_CausVid_14B_T2V_lora_rank32_v2.safetensors"
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages
    
    # MIRE models
    provisioning_get_files \
        "${COMFYUI_DIR}/models/checkpoints" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/loras" \
        "${LORA_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/ipadapter" \
        "${IPADAPTER_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/clip_vision" \
        "${CLIP_VISION_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/animatediff_models" \
        "${ANIMATEDIFF_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/animatediff_motion_lora" \
        "${ANIMATEDIFF_LORA_MODELS[@]}"
    
    # WanVideo models
    provisioning_get_files \
        "${COMFYUI_DIR}/models/diffusion_models" \
        "${DIFFUSION_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/text_encoders" \
        "${TEXT_ENCODER_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${WANVIDEO_VAE_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/loras" \
        "${WANVIDEO_LORA_MODELS[@]}"
    
    provisioning_post_process
    
    # Lock environment AFTER all node requirements are installed
    provisioning_lock_environment
    
    provisioning_print_end
}

function provisioning_lock_environment() {
    printf "\n============================================\n"
    printf "Locking environment (fixing any changes from node requirements)...\n"
    printf "============================================\n"
    
    # Force reinstall PyTorch ecosystem with exact versions
    printf "Reinstalling PyTorch ecosystem...\n"
    pip install --no-cache-dir --force-reinstall \
        torch==${TORCH_VERSION} \
        torchvision==${TORCHVISION_VERSION} \
        torchaudio==${TORCHAUDIO_VERSION} \
        --index-url https://download.pytorch.org/whl/cu121
    
    # Reinstall xformers (must be after PyTorch)
    printf "Reinstalling xformers...\n"
    pip install --no-cache-dir --force-reinstall xformers==${XFORMERS_VERSION}
    
    # Reinstall triton
    printf "Reinstalling triton...\n"
    pip install --no-cache-dir --force-reinstall triton==${TRITON_VERSION}
    
    # Install SageAttention (requires --no-build-isolation)
    printf "Installing SageAttention...\n"
    pip install --no-cache-dir --force-reinstall \
        sageattention==${SAGEATTENTION_VERSION} --no-build-isolation 2>/dev/null || \
        printf "  SageAttention install failed - continuing without it\n"
    
    # Verify
    printf "\n--- Environment Verification ---\n"
    python -c "
import torch
print(f'PyTorch: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
try:
    import xformers; print(f'xformers: {xformers.__version__}')
except: print('xformers: NOT INSTALLED')
try:
    import triton; print(f'triton: {triton.__version__}')
except: print('triton: NOT INSTALLED')
try:
    from sageattention import sageattn; print('SageAttention: OK')
except: print('SageAttention: NOT INSTALLED')
"
    printf "============================================\n\n"
}

function provisioning_post_process() {
    printf "Renaming models for workflow compatibility...\n"
    
    # Rename CLIP Vision model
    local clip_src="${COMFYUI_DIR}/models/clip_vision/open_clip_pytorch_model.safetensors"
    local clip_dst="${COMFYUI_DIR}/models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
    if [[ -f "$clip_src" && ! -f "$clip_dst" ]]; then
        mv "$clip_src" "$clip_dst"
        printf "  Renamed: CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors\n"
    fi
}

function provisioning_get_apt_packages() {
    if [[ -n $APT_PACKAGES ]]; then
        sudo $APT_INSTALL ${APT_PACKAGES[@]}
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
        pip install --no-cache-dir ${PIP_PACKAGES[@]}
    fi
}

function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="${COMFYUI_DIR}/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                    pip install --no-cache-dir -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                pip install --no-cache-dir -r "${requirements}"
            fi
        fi
    done
}

function provisioning_get_files() {
    if [[ -z $2 ]]; then return 1; fi
    
    dir="$1"
    mkdir -p "$dir"
    shift
    arr=("$@")
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
    printf "Unified Workflow: MIRE + WanVideo VACE (v2)\n\n"
}

function provisioning_print_end() {
    printf "\nProvisioning complete: Application will start now\n\n"
}

function provisioning_has_valid_hf_token() {
    [[ -n "$HF_TOKEN" ]] || return 1
    url="https://huggingface.co/api/whoami-v2"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $HF_TOKEN" \
        -H "Content-Type: application/json")

    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

function provisioning_has_valid_civitai_token() {
    [[ -n "$CIVITAI_TOKEN" ]] || return 1
    url="https://civitai.com/api/v1/models?hidden=1&limit=1"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $CIVITAI_TOKEN" \
        -H "Content-Type: application/json")

    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

function provisioning_download() {
    if [[ -n $HF_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        auth_token="$HF_TOKEN"
    elif [[ -n $CIVITAI_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
        auth_token="$CIVITAI_TOKEN"
    fi
    if [[ -n $auth_token ]]; then
        wget --header="Authorization: Bearer $auth_token" -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    else
        wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    fi
}

if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi
