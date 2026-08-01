#!/bin/bash
# bootstrap.sh
# Run this ONCE, first thing, on every fresh Radeon Cloud instance.
# Does everything needed before you can start vLLM or write code:
#   - installs ca-certificates (fixes GitHub SSL errors)
#   - installs tmux (needed to keep vLLM running in the background)
#   - restores your SSH key + git identity from /persistent
#   - installs Python packages from requirements.txt
#   - loads environment variables (persistent cache paths)
#
# After this finishes, you're ready to run: scripts/start_vllm.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "[bootstrap] Installing system packages (ca-certificates, tmux)..."
apt update -qq
apt install -y -qq ca-certificates tmux
update-ca-certificates

echo "[bootstrap] Restoring SSH key + git identity..."
source /persistent/restore_ssh.sh

echo "[bootstrap] Installing Python dependencies from requirements.txt..."
/opt/venv/bin/pip install -r "$PROJECT_DIR/requirements.txt"

echo "[bootstrap] Loading environment variables (persistent cache paths)..."
source "$PROJECT_DIR/setup_env.sh"

echo ""
echo "[bootstrap] All done. You can now run: scripts/start_vllm.sh"
