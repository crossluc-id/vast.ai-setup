#!/bin/bash

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

# ============================================================================
# CONFIGURATION SECTION - WanVideo VACE Travel Workflow
# ============================================================================

APT_PACKAGES=(
    "git-lfs"
    "ffmpeg"
)

PIP_PACKAGES=(
    "safetensors"
    "huggingface_hub"
    "transformers"
    "accelerate"
    "diffusers"
    "einops"
    "omegaconf"
    "imageio"
    "imageio-ffmpeg"
)

# PyTorch ecosystem versions - MUST match base image (v0.3.26-cuda-12.1-pytorch-2.5.1-py311)
TORCH_VERSION="2.5.1+cu121"
TORCHVISION_VERSION="0.20.1+cu121"
TORCHAUDIO_VERSION="2.5.1+cu121"
XFORMERS_VERSION="0.0.28.post3"

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
)

CHECKPOINT_MODELS=(
)

UNET_MODELS=(
)

LORA_MODELS=(
)

VAE_MODELS=(
)

ESRGAN_MODELS=(
)

CONTROLNET_MODELS=(
)

# ============================================================================
# WANVIDEO SPECIFIC MODEL ARRAYS
# ============================================================================

# WanVideo T2V Models (14B models)
WANVIDEO_T2V_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-T2V-14B_fp8_e4m3fn.safetensors"
)

# WanVideo VACE Module Models
WANVIDEO_VACE_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-VACE_module_14B_bf16.safetensors"
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VACE_1_3B_preview_bf16.safetensors"
)

# WanVideo VAE Models
WANVIDEO_VAE_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors"
)

# WanVideo LoRA Models (optional but recommended)
WANVIDEO_LORA_MODELS=(
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages
    
    # Standard model directories (keep for compatibility)
    provisioning_get_files \
        "${COMFYUI_DIR}/models/checkpoints" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/unet" \
        "${UNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/loras" \
        "${LORA_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/upscale_models" \
        "${ESRGAN_MODELS[@]}"
    
    # WanVideo specific model directories
    provisioning_get_files \
        "${COMFYUI_DIR}/models/WanVideo/t2v" \
        "${WANVIDEO_T2V_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/WanVideo/vace" \
        "${WANVIDEO_VACE_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/WanVideo/vae" \
        "${WANVIDEO_VAE_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/WanVideo/lora" \
        "${WANVIDEO_LORA_MODELS[@]}"
    
    # Lock PyTorch versions (must be last to prevent node requirements from breaking them)
    provisioning_lock_torch_versions
    
    provisioning_print_end
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

function provisioning_lock_torch_versions() {
    printf "Locking PyTorch ecosystem versions...\n"
    pip install --no-cache-dir --force-reinstall \
        torch==${TORCH_VERSION} \
        torchvision==${TORCHVISION_VERSION} \
        torchaudio==${TORCHAUDIO_VERSION} \
        xformers==${XFORMERS_VERSION} \
        --index-url https://download.pytorch.org/whl/cu121
    printf "PyTorch versions locked.\n"
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
    printf "WanVideo VACE Travel Workflow Setup\n"
    printf "Template: v0.3.26-cuda-12.1-pytorch-2.5.1-py311\n\n"
}

function provisioning_print_end() {
    printf "\nProvisioning complete:  Application will start now\n\n"
    printf "============================================\n"
    printf "WanVideo Models Installed:\n"
    printf "  - T2V Models: ${COMFYUI_DIR}/models/WanVideo/t2v/\n"
    printf "  - VACE Modules: ${COMFYUI_DIR}/models/WanVideo/vace/\n"
    printf "  - VAE Models: ${COMFYUI_DIR}/models/WanVideo/vae/\n"
    printf "============================================\n\n"
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
