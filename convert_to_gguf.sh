#!/bin/bash
# convert_to_gguf.sh — convert the fine-tuned HuggingFace model to GGUF format
#
# this is the step that was failing in the Colab notebook due to the protobuf
# conflict. run it locally after downloading your merged model from Colab.
#
# what you need first:
#   - Python 3.10+ with pip
#   - cmake (sudo apt install cmake  or  brew install cmake)
#   - the merged HF model saved locally (see "where to get the model" below)
#
# where to get the merged model:
#   run the LINUX_COPILOT.ipynb notebook in Colab, then at the end:
#     model.save_pretrained("finetuned_model")   <- saves HF format
#   download that folder and put it here as ./finetuned_model/
#
# usage:
#   chmod +x convert_to_gguf.sh
#   ./convert_to_gguf.sh
#
# output:
#   finetuned_model/unsloth.Q4_K_M.gguf  <- this is what the Modelfile points to

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC}  $1"; }
warn() { echo -e "${YELLOW}!${NC}  $1"; }
fail() { echo -e "${RED}✗${NC}  $1"; exit 1; }
step() { echo -e "\n${YELLOW}▶${NC}  $1"; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   🔧  GGUF Conversion                       ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── check inputs ──────────────────────────────────────────────────────────────
step "Checking for the HuggingFace model"

MODEL_DIR="./finetuned_model"
if [ ! -d "$MODEL_DIR" ]; then
    fail "No model found at $MODEL_DIR — download it from Colab first"
fi

# look for either safetensors or pytorch bin files
WEIGHTS=$(find "$MODEL_DIR" -name "*.safetensors" -o -name "*.bin" 2>/dev/null | head -1)
if [ -z "$WEIGHTS" ]; then
    fail "No model weights found in $MODEL_DIR — make sure you downloaded the full model folder"
fi
ok "Found model weights in $MODEL_DIR"

# ── install llama.cpp ─────────────────────────────────────────────────────────
step "Setting up llama.cpp"

LLAMACPP_DIR="./llama.cpp"

if [ -d "$LLAMACPP_DIR" ]; then
    ok "llama.cpp already present"
else
    warn "Cloning llama.cpp"
    git clone --depth 1 https://github.com/ggerganov/llama.cpp "$LLAMACPP_DIR"
fi

# build the converter (the Python scripts don't need cmake, they're just Python)
ok "llama.cpp ready"

# ── install Python requirements for conversion ─────────────────────────────
step "Installing conversion dependencies"

# fix the protobuf version that was causing issues in the notebook
pip install -q "protobuf>=3.20.3" sentencepiece transformers

ok "Dependencies installed"

# ── convert to F16 GGUF ───────────────────────────────────────────────────────
step "Converting to GGUF (F16 — full precision, ~7GB)"

F16_OUT="$MODEL_DIR/model_f16.gguf"

python "$LLAMACPP_DIR/convert_hf_to_gguf.py" \
    "$MODEL_DIR" \
    --outfile "$F16_OUT" \
    --outtype f16

ok "F16 conversion done: $F16_OUT"

# ── quantize to Q4_K_M ────────────────────────────────────────────────────────
step "Quantizing to Q4_K_M (~4GB, good quality/size tradeoff)"

# build the quantize binary if we haven't yet
if [ ! -f "$LLAMACPP_DIR/quantize" ] && [ ! -f "$LLAMACPP_DIR/build/bin/llama-quantize" ]; then
    warn "Building llama.cpp quantize tool (needs cmake)"
    mkdir -p "$LLAMACPP_DIR/build"
    cd "$LLAMACPP_DIR/build"
    cmake .. -DCMAKE_BUILD_TYPE=Release -DLLAMA_METAL=OFF 2>/dev/null
    cmake --build . --config Release -j$(nproc) 2>/dev/null
    cd -
fi

# find the quantize binary wherever it ended up
QUANTIZE=$(find "$LLAMACPP_DIR" -name "quantize" -o -name "llama-quantize" 2>/dev/null | head -1)

if [ -z "$QUANTIZE" ]; then
    warn "Could not build quantize binary (cmake might not be installed)"
    warn "The F16 GGUF was still created at $F16_OUT"
    warn "Update the Modelfile's FROM line to point at $F16_OUT instead"
    echo ""
    echo "  To quantize manually later:"
    echo "  sudo apt install cmake && ./convert_to_gguf.sh"
    exit 0
fi

Q4_OUT="$MODEL_DIR/unsloth.Q4_K_M.gguf"
"$QUANTIZE" "$F16_OUT" "$Q4_OUT" Q4_K_M

ok "Quantization done: $Q4_OUT"

# ── cleanup ───────────────────────────────────────────────────────────────────
step "Cleaning up"

# remove the big F16 file since we have the quantized version
if [ -f "$Q4_OUT" ]; then
    rm -f "$F16_OUT"
    ok "Removed intermediate F16 file (saved ~3GB)"
fi

# ── done ──────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   ✅  Conversion complete!                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Output: $Q4_OUT"
echo ""
echo "  Next step: register the model with Ollama"
echo "    ./setup.sh"
echo "  Or just run directly:"
echo "    ollama create linux-copilot -f Modelfile"
echo "    python run_assistant.py"
echo ""
