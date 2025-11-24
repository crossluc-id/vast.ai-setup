#!/bin/bash

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

# ============================================================================
# CONFIGURATION SECTION - MIRE Video Workflow
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
)

# PyTorch ecosystem versions - MUST match base image
TORCH_VERSION="2.5.1+cu121"
TORCHVISION_VERSION="0.20.1+cu121"
TORCHAUDIO_VERSION="2.5.1+cu121"
XFORMERS_VERSION="0.0.28.post3"

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/banodoco/steerable-motion"
    "https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved"
    "https://github.com/Fannovel16/comfyui-advanced-controlnet"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
    "https://github.com/FizzleDorf/ComfyUI_FizzNodes"
    "https://github.com/BadCafeCode/masquerade-nodes-comfyui"
    "https://github.com/jags111/efficiency-nodes-comfyui"
    "https://github.com/alt-key-project/comfyui-dream-project"
    "https://github.com/kijai/ComfyUI-KJNodes"
)

CHECKPOINT_MODELS=(
    "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
)

UNET_MODELS=(
)

LORA_MODELS=(
    # AnimateLCM LoRA (official source)
    "https://huggingface.co/wangfuyun/AnimateLCM/resolve/main/AnimateLCM_sd15_t2v_lora.safetensors"
)

VAE_MODELS=(
    "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"
)

ESRGAN_MODELS=(
    "https://huggingface.co/DervlexVenice/kagome_higurashi_inuyasha-style-1.5/resolve/main/2xHigurashi_v1_compact_270k.pth"
)

CONTROLNET_MODELS=(
    "https://huggingface.co/guoyww/animatediff/resolve/main/v3_sd15_sparsectrl_rgb.ckpt"
    "https://huggingface.co/lllyasviel/ControlNet-v1-1-fp16/resolve/main/control_v11p_sd15_openpose_fp16.safetensors"
)

# ============================================================================
# CUSTOM MODEL ARRAYS (for non-standard directories)
# ============================================================================

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

FRAME_INTERPOLATION_MODELS=(
    "https://huggingface.co/FILM-Model/pretrained_models/resolve/main/film_net_fp32.pt"
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages
    
    # Standard model directories
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
    
    # Custom model directories
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
    provisioning_get_files \
        "${COMFYUI_DIR}/custom_nodes/ComfyUI-Frame-Interpolation/ckpts/film" \
        "${FRAME_INTERPOLATION_MODELS[@]}"
    
    # Rename files for workflow compatibility
    provisioning_post_process
    
    # Lock PyTorch versions (must be last to prevent node requirements from breaking them)
    provisioning_lock_torch_versions
    
    provisioning_print_end
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
    
    # Copy LoRA to LCM subdirectory (some workflows expect this)
    local lora_src="${COMFYUI_DIR}/models/loras/AnimateLCM_sd15_t2v_lora.safetensors"
    local lora_lcm_dir="${COMFYUI_DIR}/models/loras/LCM/SD1.5"
    if [[ -f "$lora_src" ]]; then
        mkdir -p "$lora_lcm_dir"
        if [[ ! -f "${lora_lcm_dir}/AnimateLCM_sd15_t2v_lora.safetensors" ]]; then
            cp "$lora_src" "$lora_lcm_dir/"
            printf "  Copied LoRA to: LCM/SD1.5/\n"
        fi
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
}

function provisioning_print_end() {
    printf "\nProvisioning complete:  Application will start now\n\n"
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
