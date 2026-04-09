#!/bin/bash
# setup.sh — one-shot setup for the Linux Co-Pilot assistant
#
# what this does:
#   1. checks if Ollama is installed, installs it if not
#   2. starts Ollama in the background if it's not already running
#   3. installs Python dependencies
#   4. registers the model with Ollama using the Modelfile
#
# usage:
#   chmod +x setup.sh
#   ./setup.sh
 
set -e   # stop on first error
 
# ── colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'   # no colour
 
ok()   { echo -e "${GREEN}✓${NC}  $1"; }
warn() { echo -e "${YELLOW}!${NC}  $1"; }
fail() { echo -e "${RED}✗${NC}  $1"; exit 1; }
step() { echo -e "\n${YELLOW}▶${NC}  $1"; }
 
echo ""
echo "Linux Co-Pilot — Setup"
echo ""
 
# ── 1. check for the GGUF file ────────────────────────────────────────────────
step "Checking for the fine-tuned model file"
 
GGUF_PATH="./finetuned_model/unsloth.Q4_K_M.gguf"
 
if [ ! -f "$GGUF_PATH" ]; then
    warn "GGUF file not found at $GGUF_PATH"
    echo ""
    echo "  You need to export your fine-tuned model first."
    echo "  Run the Colab notebook (LINUX_COPILOT.ipynb) and download the GGUF."
    echo "  Then put it at:  finetuned_model/unsloth.Q4_K_M.gguf"
    echo ""
    echo "  If your file has a different name, update the FROM line in Modelfile."
    echo ""
    read -p "  Continue anyway? (y/N) " yn
    [[ "$yn" =~ ^[Yy]$ ]] || exit 0
else
    ok "Found model at $GGUF_PATH"
fi
 
# ── 2. install Ollama ─────────────────────────────────────────────────────────
step "Checking for Ollama"
 
if command -v ollama &>/dev/null; then
    ok "Ollama already installed: $(ollama --version 2>/dev/null || echo 'version unknown')"
else
    warn "Ollama not found — installing now"
    echo "  (this downloads ~100 MB, needs curl)"
    curl -fsSL https://ollama.com/install.sh | sh
    ok "Ollama installed"
fi
 
# ── 3. start Ollama if not running ────────────────────────────────────────────
step "Starting Ollama server"
 
if curl -s http://localhost:11434/ &>/dev/null; then
    ok "Ollama is already running"
else
    warn "Starting Ollama in the background"
    ollama serve &>/dev/null &
    OLLAMA_PID=$!
    echo "  PID: $OLLAMA_PID"
 
    # give it a few seconds to wake up
    sleep 3
 
    if curl -s http://localhost:11434/ &>/dev/null; then
        ok "Ollama is up"
    else
        fail "Ollama didn't start — try running 'ollama serve' manually"
    fi
fi
 
# ── 4. install Python deps ────────────────────────────────────────────────────
step "Installing Python dependencies"
 
if ! command -v pip &>/dev/null; then
    fail "pip not found — install Python 3.9+ first"
fi
 
pip install -q -r requirements.txt
ok "Python packages installed"
 
# ── 5. register the model with Ollama ────────────────────────────────────────
step "Creating the linux-copilot model in Ollama"
 
if [ ! -f "Modelfile" ]; then
    fail "Modelfile not found in current directory"
fi
 
ollama create linux-copilot -f Modelfile
ok "Model registered as 'linux-copilot'"
 
# ── done ──────────────────────────────────────────────────────────────────────
echo ""
echo "Setup complete!"
echo "  Start the assistant:   python run_assistant.py"
echo "  Or use Ollama direct:  ollama run linux-copilot"
echo ""
