#!/bin/bash
# AI-Flow ComfyUI Provisioning Script
# Installs custom nodes and downloads required models for InfiniteTalk, Wan 2.1,
# and video generation workflows.
# Designed to be used as PROVISIONING_SCRIPT env var with the Vast.ai ComfyUI template.
#
# Usage: Set PROVISIONING_SCRIPT=<raw_url_to_this_file> in instance env vars.
# The ComfyUI template runs this automatically on first boot.
#
# Based on Vast.ai's provisioning conventions:
# https://raw.githubusercontent.com/vast-ai/base-image/refs/heads/main/derivatives/pytorch/derivatives/comfyui/provisioning_scripts/default.sh

set -e

# Use WORKSPACE env var from Vast.ai template, fallback to /workspace
COMFYUI_DIR="${WORKSPACE:-/workspace}/ComfyUI"
MODELS_DIR="$COMFYUI_DIR/models"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"

# Use the venv pip if available (Vast.ai ComfyUI templates use /venv/main/)
if [ -f "/venv/main/bin/pip" ]; then
    PIP="/venv/main/bin/pip"
elif [ -f "$COMFYUI_DIR/venv/bin/pip" ]; then
    PIP="$COMFYUI_DIR/venv/bin/pip"
else
    PIP="pip"
fi

echo "========================================"
echo "AI-Flow: Starting provisioning..."
echo "Using pip: $PIP"
echo "ComfyUI dir: $COMFYUI_DIR"
echo "========================================"

# ---- Custom Nodes ----
# Follows Vast.ai template convention: git clone --recursive + pip install requirements
echo "--- Installing Custom Nodes ---"

NODES=(
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/kijai/ComfyUI-MelBandRoFormer"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/scofano/comfy-audio-duration"
)

for repo in "${NODES[@]}"; do
    dir_name="${repo##*/}"
    path="$CUSTOM_NODES_DIR/$dir_name"
    if [ -d "$path" ]; then
        echo "[UPDATE] $dir_name ..."
        ( cd "$path" && git pull )
        if [ -f "$path/requirements.txt" ]; then
            $PIP install --no-cache-dir -r "$path/requirements.txt"
        fi
    else
        echo "[INSTALL] $dir_name ..."
        git clone "$repo" "$path" --recursive
        if [ -f "$path/requirements.txt" ]; then
            $PIP install --no-cache-dir -r "$path/requirements.txt"
        fi
    fi
done

# ---- Model Downloads ----
echo "--- Downloading Models ---"

# Create target directories
mkdir -p "$MODELS_DIR/diffusion_models" \
         "$MODELS_DIR/text_encoders" \
         "$MODELS_DIR/loras" \
         "$MODELS_DIR/vae" \
         "$MODELS_DIR/clip_vision" \
         "$MODELS_DIR/wav2vec2"

# Download helper with HuggingFace token support (follows Vast.ai convention)
download() {
    local url="$1"
    local dir="$2"
    local filename
    filename=$(basename "$url" | sed 's/?.*//')
    local dest="$dir/$filename"

    if [ -f "$dest" ]; then
        echo "[SKIP] $filename already exists"
        return
    fi

    echo "[DOWNLOAD] $filename ..."
    if [[ -n $HF_TOKEN && $url =~ huggingface\.co ]]; then
        wget --header="Authorization: Bearer $HF_TOKEN" -qnc --content-disposition --show-progress -e dotbytes=4M -P "$dir" "$url"
    else
        wget -qnc --content-disposition --show-progress -e dotbytes=4M -P "$dir" "$url"
    fi
    echo "[DONE] $filename"
}

# Text Encoders
echo "--- Text Encoders ---"
download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors" \
    "$MODELS_DIR/text_encoders"

# Diffusion Models
echo "--- Diffusion Models ---"
download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/InfiniteTalk/Wan2_1-InfiniTetalk-Single_fp16.safetensors" \
    "$MODELS_DIR/diffusion_models"

download "https://huggingface.co/DeepBeepMeep/Wan2.1/resolve/4da0bbfdad01e159633083e98be7f93d8b8c9562/wan2.1_image2video_480p_14B_bf16.safetensors" \
    "$MODELS_DIR/diffusion_models"

download "https://huggingface.co/DeepBeepMeep/Wan2.1/resolve/main/wan2.1_image2video_720p_14B_mbf16.safetensors" \
    "$MODELS_DIR/diffusion_models"

download "https://huggingface.co/Kijai/MelBandRoFormer_comfy/resolve/main/MelBandRoformer_fp16.safetensors" \
    "$MODELS_DIR/diffusion_models"

# LoRAs
echo "--- LoRAs ---"
download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank128_bf16.safetensors" \
    "$MODELS_DIR/loras"

# VAE
echo "--- VAE ---"
download "https://huggingface.co/DeepBeepMeep/Wan2.1/resolve/4da0bbfdad01e159633083e98be7f93d8b8c9562/Wan2.1_VAE_bf16.safetensors" \
    "$MODELS_DIR/vae"

download "https://huggingface.co/DeepBeepMeep/Wan2.1/resolve/4da0bbfdad01e159633083e98be7f93d8b8c9562/Wan2.1_VAE.safetensors" \
    "$MODELS_DIR/vae"

# CLIP Vision
echo "--- CLIP Vision ---"
download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
    "$MODELS_DIR/clip_vision"

# Wav2Vec2 (for InfiniteTalk audio sync)
echo "--- Wav2Vec2 ---"
download "https://huggingface.co/Kijai/wav2vec2_safetensors/resolve/main/wav2vec2-chinese-base_fp32.safetensors" \
    "$MODELS_DIR/wav2vec2"

download "https://huggingface.co/Kijai/wav2vec2_safetensors/resolve/main/wav2vec2-chinese-base_fp16.safetensors" \
    "$MODELS_DIR/wav2vec2"

echo "========================================"
echo "AI-Flow: Provisioning complete!"
echo "========================================"
