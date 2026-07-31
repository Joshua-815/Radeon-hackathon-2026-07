#!/bin/bash
# setup_env.sh
# Run this ONCE every time you launch a fresh Radeon Cloud instance:
#   source /workspace/setup_env.sh
#
# Purpose: point everything at /workspace (persistent storage) instead of
# the instance's local disk, so model downloads / caches survive a
# destroy+relaunch. (This is the fix we figured out on Day 2 originally.)

# --- Hugging Face model cache -> persistent /workspace, not local disk ---
export HF_HUB_CACHE=/workspace/hf_cache

# --- vLLM compiled-graph cache -> also persistent, avoids full rebuild each launch ---
export VLLM_CACHE_ROOT=/workspace/vllm_cache
mkdir -p "$VLLM_CACHE_ROOT"

# --- Make sure the ROCm venv is on PATH for this shell ---
export PATH="/opt/venv/bin:$PATH"

echo "[setup_env] HF_HUB_CACHE=$HF_HUB_CACHE"
echo "[setup_env] VLLM_CACHE_ROOT=$VLLM_CACHE_ROOT"
echo "[setup_env] Done. Next: apt update && apt install -y tmux, then start vLLM in tmux."
