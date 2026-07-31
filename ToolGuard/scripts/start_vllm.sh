#!/bin/bash
# start_vllm.sh
# Starts the local model server inside a tmux session named "vllm",
# so it keeps running even if your terminal disconnects.
#
# Works no matter which folder you call it from or where you are -
# it finds its own location first, so "scripts/start_vllm.sh",
# "./start_vllm.sh", and "bash start_vllm.sh" from anywhere all work.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

SESSION="vllm"

if tmux has-session -t $SESSION 2>/dev/null; then
    if [ -n "$TMUX" ]; then
        echo "[start_vllm] Session '$SESSION' already running. Switching to it..."
        tmux switch-client -t $SESSION
    else
        echo "[start_vllm] Session '$SESSION' already running. Attaching..."
        tmux attach -t $SESSION
    fi
else
    echo "[start_vllm] Starting new vLLM session..."
    tmux new-session -d -s $SESSION \
      "/opt/venv/bin/vllm serve Qwen/Qwen2.5-7B-Instruct --host 0.0.0.0 --port 8000 --enable-auto-tool-choice --tool-call-parser hermes"
    echo "[start_vllm] Started in background. Attach anytime with: tmux attach -t $SESSION"
    echo "[start_vllm] Detach without stopping it: Ctrl+B then D"
fi
