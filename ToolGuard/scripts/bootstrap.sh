#!/bin/bash
# bootstrap.sh
# Run this ONCE, first thing, on every fresh Radeon Cloud instance.
#
# OFFLINE-FIRST: after the very first successful run, this script
# caches everything it downloads into /persistent, so future runs
# on future fresh instances don't need the internet at all (except
# the model weights, which vLLM/setup_env.sh already caches separately).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APT_CACHE="/persistent/apt_cache"
PIP_CACHE="/persistent/pip_cache"

mkdir -p "$APT_CACHE" "$PIP_CACHE"

echo "[bootstrap] Checking system packages (ca-certificates, tmux)..."
if command -v tmux >/dev/null 2>&1 && [ -f /etc/ssl/certs/ca-certificates.crt ]; then
    echo "[bootstrap] tmux + ca-certificates already present. Skipping install."
else
    if ls "$APT_CACHE"/*.deb >/dev/null 2>&1; then
        echo "[bootstrap] Found cached .deb packages in $APT_CACHE - installing offline, no internet needed..."
        dpkg -i "$APT_CACHE"/*.deb || apt-get install -f -y -qq
    else
        echo "[bootstrap] No cache found yet - downloading once from the internet (first time only)..."
        apt update -qq
        apt install -y -qq --download-only -o Dir::Cache::Archives="$APT_CACHE" ca-certificates tmux
        apt install -y -qq ca-certificates tmux
        echo "[bootstrap] Cached for next time at $APT_CACHE - future instances won't need internet for this step."
    fi
    update-ca-certificates
fi

echo "[bootstrap] Restoring SSH key + git identity..."
source /persistent/restore_ssh.sh

echo "[bootstrap] Installing Python dependencies from requirements.txt..."
if [ -d "$PIP_CACHE" ] && [ "$(ls -A "$PIP_CACHE" 2>/dev/null)" ]; then
    echo "[bootstrap] Found cached Python packages in $PIP_CACHE - installing offline, no internet needed..."
    /opt/venv/bin/pip install --no-index --find-links="$PIP_CACHE" -r "$PROJECT_DIR/requirements.txt" \
      || /opt/venv/bin/pip install -r "$PROJECT_DIR/requirements.txt"
else
    echo "[bootstrap] No cache found yet - downloading once from the internet (first time only)..."
    /opt/venv/bin/pip download -r "$PROJECT_DIR/requirements.txt" -d "$PIP_CACHE"
    /opt/venv/bin/pip install -r "$PROJECT_DIR/requirements.txt"
    echo "[bootstrap] Cached for next time at $PIP_CACHE - future instances won't need internet for this step."
fi

echo "[bootstrap] Loading environment variables (persistent cache paths)..."
source "$PROJECT_DIR/setup_env.sh"

echo ""
echo "[bootstrap] All done. You can now run: scripts/start_vllm.sh"
