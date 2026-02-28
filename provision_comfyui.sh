#!/bin/bash
# AI-Flow ComfyUI Provisioning Script
# Downloads required models for InfiniteTalk, Wan 2.1, and video generation workflows.
# Designed to be used as PROVISIONING_SCRIPT env var with the Vast.ai ComfyUI template.
#
# Usage: Set PROVISIONING_SCRIPT=<raw_url_to_this_file> in instance env vars.
# The ComfyUI template runs this automatically on first boot.

set -e

MODELS_DIR="/workspace/ComfyUI/models"

echo "========================================"
echo "AI-Flow: Starting model provisioning..."
echo "========================================"

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
