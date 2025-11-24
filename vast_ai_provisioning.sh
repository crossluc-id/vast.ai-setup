#!/bin/bash

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

# ============================================================================
# CONFIGURATION SECTION - MIRE Video Workflow Requirements
# ============================================================================

# System packages to install via apt
APT_PACKAGES=(
    "git-lfs"
    "ffmpeg"
)

# Python packages to install via pip
PIP_PACKAGES=(
    "safetensors"
    "huggingface_hub"
    "xformers==0.0.22"
    "insightface"
    "onnxruntime-gpu"
)

# Custom nodes for MIRE Video workflow
NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
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
    "https://github.com/alt-key-project/comfyui-dream-project.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
)

# Workflow files (will be handled separately)
WORKFLOWS=(
    # Workflows are typically uploaded manually or via separate script
)

# Checkpoint models (SD 1.5 base model)
CHECKPOINT_MODELS=(
    "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
)

# UNET models (not used in MIRE workflow)
UNET_MODELS=(
)

# LoRA models
LORA_MODELS=(
    # LCM LoRA for SD 1.5 - will be placed in root and LCM/SD1.5 subdirectory
    "https://huggingface.co/chun061205/lcm-lora-sd15/resolve/main/adapter_model.safetensors"
    # Note: This downloads as adapter_model.safetensors, will be renamed by post-processing
)

# VAE models
VAE_MODELS=(
    "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"
)

# ESRGAN/upscale models
ESRGAN_MODELS=(
    # 2xHigurashi upscaler - workflow expects .pth format
    # Note: If .pth not available, will try .safetensors in post-processing
    "https://huggingface.co/DervlexVenice/kagome_higurashi_inuyasha-style-1.5/resolve/main/2xHigurashi_v1_compact_270k.pth"
)

# ControlNet models
CONTROLNET_MODELS=(
    "https://huggingface.co/guoyww/animatediff/resolve/main/v3_sd15_sparsectrl_rgb.ckpt"
    # OpenPoseXL2 (for HighRes-Fix Script node)
    "https://huggingface.co/lllyasviel/ControlNet-v1-1-fp16/resolve/main/control_v11p_sd15_openpose_fp16.safetensors"
)

# ============================================================================
# ADDITIONAL MODEL ARRAYS (extending template functionality)
# ============================================================================

# IP-Adapter models (custom directory)
IPADAPTER_MODELS=(
    "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter-plus_sd15.safetensors"
)

# CLIP Vision models (custom directory)
CLIP_VISION_MODELS=(
    # CLIP ViT-L/14 - LAION-2B (primary, commonly required)
    "https://huggingface.co/laion/CLIP-ViT-L-14-laion2B-s32B-b82K/resolve/main/open_clip_pytorch_model.safetensors"
    # CLIP ViT-H/14 - LAION-2B (workflow default, optional)
    "https://huggingface.co/laion/CLIP-ViT-H-14-laion2B-s32B-b79K/resolve/main/open_clip_pytorch_model.safetensors"
)

# AnimateDiff motion models (custom directory)
ANIMATEDIFF_MOTION_MODELS=(
    "https://huggingface.co/guoyww/animatediff/resolve/main/v3_sd15_mm.ckpt"
)

# AnimateDiff motion LoRAs (custom directory)
ANIMATEDIFF_MOTION_LORA_MODELS=(
    "https://huggingface.co/peteromallet/poms-funtime-mlora-emporium/resolve/main/LiquidAF-0-1.safetensors"
)

# Frame interpolation models (custom directory)
FRAME_INTERPOLATION_MODELS=(
    "https://huggingface.co/FILM-Model/pretrained_models/resolve/main/film_net_fp32.pt"
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    provisioning_print_header
    
    # Create all necessary directories first
    provisioning_create_directories
    
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages
    
    # Standard model downloads (using template functions)
    provisioning_get_files \
        "${COMFYUI_DIR}/models/checkpoints" \
        "${CHECKPOINT_MODELS[@]}"
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/unet" \
        "${UNET_MODELS[@]}"
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/lora" \
        "${LORA_MODELS[@]}"
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS[@]}"
    
    provisioning_get_files \
        "${COMFYUI_DIR}/models/esrgan" \
        "${ESRGAN_MODELS[@]}"
    
    # Custom model downloads (MIRE workflow specific)
    provisioning_get_custom_models
    
    # Post-processing: rename files, create subdirectories, etc.
    provisioning_post_process
    
    provisioning_print_end
}

function provisioning_create_directories() {
    printf "Creating model directories...\n"
    mkdir -p "${COMFYUI_DIR}/models/checkpoints"
    mkdir -p "${COMFYUI_DIR}/models/vae"
    mkdir -p "${COMFYUI_DIR}/models/ipadapter"
    mkdir -p "${COMFYUI_DIR}/models/clip_vision"
    mkdir -p "${COMFYUI_DIR}/models/animatediff_motion"
    mkdir -p "${COMFYUI_DIR}/models/animatediff_motion_lora"
    mkdir -p "${COMFYUI_DIR}/models/controlnet"
    mkdir -p "${COMFYUI_DIR}/models/loras"
    mkdir -p "${COMFYUI_DIR}/models/loras/LCM/SD1.5"
    mkdir -p "${COMFYUI_DIR}/models/upscale_models"
    mkdir -p "${COMFYUI_DIR}/models/frame_interpolation"
    mkdir -p "${COMFYUI_DIR}/custom_nodes"
}

function provisioning_get_custom_models() {
    # IP-Adapter models
    if [[ -n $IPADAPTER_MODELS ]]; then
        provisioning_get_files \
            "${COMFYUI_DIR}/models/ipadapter" \
            "${IPADAPTER_MODELS[@]}"
    fi
    
    # CLIP Vision models (need special handling for filename conversion)
    if [[ -n $CLIP_VISION_MODELS ]]; then
        printf "Downloading CLIP Vision models...\n"
        for url in "${CLIP_VISION_MODELS[@]}"; do
            printf "Downloading: %s\n" "${url}"
            
            # Determine target filename based on URL before download
            if [[ $url == *"ViT-L-14"* ]]; then
                target_name="CLIP-ViT-L-14-laion2B-s32B-b82K.safetensors"
            elif [[ $url == *"ViT-H-14"* ]]; then
                target_name="CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
            else
                target_name=""
            fi
            
            # Download to temporary location first
            temp_dir="${COMFYUI_DIR}/models/clip_vision/temp"
            mkdir -p "$temp_dir"
            provisioning_download "${url}" "$temp_dir"
            
            # Find the downloaded file (wget with --content-disposition may rename it)
            downloaded_file=$(find "$temp_dir" -name "*.safetensors" -type f | head -n 1)
            
            if [[ -n "$downloaded_file" && -f "$downloaded_file" ]]; then
                target_file="${COMFYUI_DIR}/models/clip_vision/${target_name}"
                
                # Only rename if target doesn't exist
                if [[ ! -f "$target_file" ]]; then
                    mv "$downloaded_file" "$target_file"
                    printf "Saved as: %s\n" "${target_name}"
                else
                    printf "Model already exists: %s\n" "${target_name}"
                    rm -f "$downloaded_file"
                fi
            else
                printf "Warning: Could not find downloaded CLIP Vision model\n"
            fi
            
            # Clean up temp directory
            rmdir "$temp_dir" 2>/dev/null || true
            printf "\n"
        done
    fi
    
    # AnimateDiff motion models
    if [[ -n $ANIMATEDIFF_MOTION_MODELS ]]; then
        provisioning_get_files \
            "${COMFYUI_DIR}/models/animatediff_motion" \
            "${ANIMATEDIFF_MOTION_MODELS[@]}"
        
        # Rename v3_sd15_mm.ckpt to AnimateLCM_sd15_t2v.ckpt for workflow compatibility
        motion_file="${COMFYUI_DIR}/models/animatediff_motion/v3_sd15_mm.ckpt"
        target_file="${COMFYUI_DIR}/models/animatediff_motion/AnimateLCM_sd15_t2v.ckpt"
        if [[ -f "$motion_file" && ! -f "$target_file" ]]; then
            cp "$motion_file" "$target_file"
            printf "Created workflow-compatible copy: AnimateLCM_sd15_t2v.ckpt\n"
        fi
    fi
    
    # AnimateDiff motion LoRAs
    if [[ -n $ANIMATEDIFF_MOTION_LORA_MODELS ]]; then
        provisioning_get_files \
            "${COMFYUI_DIR}/models/animatediff_motion_lora" \
            "${ANIMATEDIFF_MOTION_LORA_MODELS[@]}"
    fi
    
    # Frame interpolation models
    if [[ -n $FRAME_INTERPOLATION_MODELS ]]; then
        provisioning_get_files \
            "${COMFYUI_DIR}/models/frame_interpolation" \
            "${FRAME_INTERPOLATION_MODELS[@]}"
    fi
}

function provisioning_post_process() {
    printf "\nPost-processing downloaded models...\n"
    
    # Rename OpenPose model for workflow compatibility
    openpose_source="${COMFYUI_DIR}/models/controlnet/control_v11p_sd15_openpose_fp16.safetensors"
    openpose_target="${COMFYUI_DIR}/models/controlnet/OpenPoseXL2.safetensors"
    if [[ -f "$openpose_source" && ! -f "$openpose_target" ]]; then
        cp "$openpose_source" "$openpose_target"
        printf "Created workflow-compatible copy: OpenPoseXL2.safetensors\n"
    fi
    
    # Rename LCM LoRA (template downloads to models/lora, workflow may need models/loras)
    lora_source="${COMFYUI_DIR}/models/lora/adapter_model.safetensors"
    lora_target_root="${COMFYUI_DIR}/models/loras/AnimateLCM_sd15_t2v_lora.safetensors"
    lora_target_alt="${COMFYUI_DIR}/models/lora/AnimateLCM_sd15_t2v_lora.safetensors"
    
    if [[ -f "$lora_source" ]]; then
        # Rename in original location
        if [[ ! -f "$lora_target_alt" ]]; then
            mv "$lora_source" "$lora_target_alt"
            printf "Renamed LCM LoRA: AnimateLCM_sd15_t2v_lora.safetensors\n"
        fi
        
        # Also copy to models/loras directory (workflow compatibility)
        if [[ ! -f "$lora_target_root" ]]; then
            mkdir -p "${COMFYUI_DIR}/models/loras"
            cp "$lora_target_alt" "$lora_target_root"
            printf "Copied LCM LoRA to models/loras directory\n"
        fi
        
        # Copy to LCM/SD1.5 subdirectory for workflow compatibility
        lcm_dir="${COMFYUI_DIR}/models/loras/LCM/SD1.5"
        lcm_target="${lcm_dir}/AnimateLCM_sd15_t2v_lora.safetensors"
        mkdir -p "$lcm_dir"
        if [[ ! -f "$lcm_target" ]]; then
            cp "$lora_target_root" "$lcm_target"
            printf "Copied LCM LoRA to LCM/SD1.5 subdirectory\n"
        fi
    fi
    
    # Move upscale model to correct directory if needed
    upscale_source_esrgan="${COMFYUI_DIR}/models/esrgan/2xHigurashi_v1_compact_270k.pth"
    upscale_source_safetensors="${COMFYUI_DIR}/models/esrgan/Kagome_Higurashi_InuYasha_20272.safetensors"
    upscale_target="${COMFYUI_DIR}/models/upscale_models/2xHigurashi_v1_compact_270k.pth"
    
    mkdir -p "${COMFYUI_DIR}/models/upscale_models"
    
    if [[ -f "$upscale_source_esrgan" && ! -f "$upscale_target" ]]; then
        mv "$upscale_source_esrgan" "$upscale_target"
        printf "Moved upscale model (.pth) to upscale_models directory\n"
    elif [[ -f "$upscale_source_safetensors" && ! -f "$upscale_target" ]]; then
        # Fallback: if .pth not available, try downloading .safetensors and convert
        printf "Warning: .pth upscale model not found, workflow may need manual download\n"
        printf "  Expected: %s\n" "$upscale_target"
    fi
    
    printf "Post-processing complete.\n"
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
        path="${COMFYUI_DIR}custom_nodes/${dir}"
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

    # Check if the token is valid
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

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

# Download from $1 URL to $2 file path
function provisioning_download() {
    if [[ -n $HF_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        auth_token="$HF_TOKEN"
    elif [[ -n $CIVITAI_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
        auth_token="$CIVITAI_TOKEN"
    fi
    if [[ -n $auth_token ]];then
        wget --header="Authorization: Bearer $auth_token" -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    else
        wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    fi
}

# Allow user to disable provisioning if they started with a script they didn't want
if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi

