#!/bin/bash
# AI-Flow ComfyUI Provisioning Script
# Installs custom nodes and downloads required models for InfiniteTalk, Wan 2.1,
# and video generation workflows.
# Designed to be used as PROVISIONING_SCRIPT env var with the Vast.ai ComfyUI template.
#
# Usage: Set PROVISIONING_SCRIPT=<raw_url_to_this_file> in instance env vars.
# The ComfyUI template runs this automatically on first boot.

set -e

COMFYUI_DIR="/workspace/ComfyUI"
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
echo "Using pip: $PIP"

echo "========================================"
echo "AI-Flow: Starting provisioning..."
echo "========================================"

# ---- Custom Nodes ----
echo "--- Installing Custom Nodes ---"

install_node() {
    local repo_url="$1"
    local dir_name
    dir_name=$(basename "$repo_url" .git)
    if [ -d "$CUSTOM_NODES_DIR/$dir_name" ]; then
        echo "[SKIP] $dir_name already installed"
    else
        echo "[INSTALL] $dir_name ..."
        git clone "$repo_url" "$CUSTOM_NODES_DIR/$dir_name"
        if [ -f "$CUSTOM_NODES_DIR/$dir_name/requirements.txt" ]; then
            echo "[DEPS] Installing requirements for $dir_name ..."
            $PIP install -r "$CUSTOM_NODES_DIR/$dir_name/requirements.txt" 2>&1 | tail -5
        fi
        echo "[DONE] $dir_name"
    fi
}

# WanVideo wrapper (InfiniteTalk, MultiTalk, Wav2Vec nodes)
install_node "https://github.com/kijai/ComfyUI-WanVideoWrapper.git"

# KJNodes (FloatConstant, ImageResizeKJ, INTConstant, SimpleCalculator, etc.)
install_node "https://github.com/kijai/ComfyUI-KJNodes.git"

# MelBandRoFormer (audio source separation for InfiniteTalk)
install_node "https://github.com/kijai/ComfyUI-MelBandRoFormer.git"

# VideoHelperSuite (VHS_VideoCombine for video output)
install_node "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"

# Create target directories
mkdir -p "$MODELS_DIR/diffusion_models" \
         "$MODELS_DIR/text_encoders" \
         "$MODELS_DIR/loras" \
         "$MODELS_DIR/vae" \
         "$MODELS_DIR/clip_vision" \
         "$MODELS_DIR/wav2vec2"

# Helper: download if not already present
download() {
    local dest="$1"
    local url="$2"
    local filename
    filename=$(basename "$dest")
    if [ -f "$dest" ]; then
        echo "[SKIP] $filename already exists"
    else
        echo "[DOWNLOAD] $filename ..."
        wget -q --show-progress -O "$dest" "$url"
        echo "[DONE] $filename"
    fi
}

# ---- Text Encoders ----
echo "--- Text Encoders ---"
download "$MODELS_DIR/text_encoders/umt5-xxl-enc-bf16.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors"

# ---- Diffusion Models ----
echo "--- Diffusion Models ---"
download "$MODELS_DIR/diffusion_models/Wan2_1-InfiniTetalk-Single_fp16.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/InfiniteTalk/Wan2_1-InfiniTetalk-Single_fp16.safetensors"

download "$MODELS_DIR/diffusion_models/wan2.1_image2video_480p_14B_bf16.safetensors" \
    "https://huggingface.co/DeepBeepMeep/Wan2.1/resolve/4da0bbfdad01e159633083e98be7f93d8b8c9562/wan2.1_image2video_480p_14B_bf16.safetensors"

download "$MODELS_DIR/diffusion_models/wan2.1_image2video_720p_14B_mbf16.safetensors" \
    "https://huggingface.co/DeepBeepMeep/Wan2.1/resolve/main/wan2.1_image2video_720p_14B_mbf16.safetensors"

download "$MODELS_DIR/diffusion_models/MelBandRoformer_fp16.safetensors" \
    "https://huggingface.co/Kijai/MelBandRoFormer_comfy/resolve/main/MelBandRoformer_fp16.safetensors"

# ---- LoRAs ----
echo "--- LoRAs ---"
download "$MODELS_DIR/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank128_bf16.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank128_bf16.safetensors"

# ---- VAE ----
echo "--- VAE ---"
download "$MODELS_DIR/vae/Wan2.1_VAE_bf16.safetensors" \
    "https://huggingface.co/DeepBeepMeep/Wan2.1/resolve/4da0bbfdad01e159633083e98be7f93d8b8c9562/Wan2.1_VAE_bf16.safetensors"

download "$MODELS_DIR/vae/Wan2.1_VAE.safetensors" \
    "https://huggingface.co/DeepBeepMeep/Wan2.1/resolve/4da0bbfdad01e159633083e98be7f93d8b8c9562/Wan2.1_VAE.safetensors"

# ---- CLIP Vision ----
echo "--- CLIP Vision ---"
download "$MODELS_DIR/clip_vision/clip_vision_h.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

# ---- Wav2Vec2 (for InfiniteTalk audio sync) ----
echo "--- Wav2Vec2 ---"
download "$MODELS_DIR/wav2vec2/wav2vec2-chinese-base_fp32.safetensors" \
    "https://huggingface.co/Kijai/wav2vec2_safetensors/resolve/main/wav2vec2-chinese-base_fp32.safetensors"

download "$MODELS_DIR/wav2vec2/wav2vec2-chinese-base_fp16.safetensors" \
    "https://huggingface.co/Kijai/wav2vec2_safetensors/resolve/main/wav2vec2-chinese-base_fp16.safetensors"

echo "========================================"
echo "AI-Flow: Provisioning complete!"
echo "========================================"
