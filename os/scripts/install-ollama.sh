#!/bin/bash
# ============================================================================
# CursorOS - Ollama AI Installer
# ============================================================================
# Installs Ollama (https://ollama.ai) for running local AI models.
#
# Usage:
#   install-ollama              # Install Ollama
#   install-ollama --with-model # Install Ollama + download a starter model
# ============================================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}  ============================================${NC}"
echo -e "${CYAN}   CursorOS - Ollama AI Installer${NC}"
echo -e "${CYAN}  ============================================${NC}"
echo ""

# Check for internet connectivity
echo -e "${YELLOW}[1/4]${NC} Checking internet connection..."
if ! ping -c 1 -W 3 google.com &>/dev/null && ! ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
    echo -e "${RED}No internet connection detected!${NC}"
    echo "Please connect to the internet first:"
    echo "  - Click the network icon in the system tray"
    echo "  - Or run: nmtui (for terminal-based network setup)"
    exit 1
fi
echo -e "${GREEN}  Internet connection OK${NC}"

# Check system requirements
echo -e "${YELLOW}[2/4]${NC} Checking system requirements..."
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
FREE_DISK=$(df -BM / | awk 'NR==2{print $4}' | tr -d 'M')

echo "  RAM:  ${TOTAL_RAM} MB"
echo "  Disk: ${FREE_DISK} MB free"

if [ "$TOTAL_RAM" -lt 2048 ]; then
    echo -e "${YELLOW}Warning: Less than 2GB RAM. Small models only.${NC}"
fi

if [ "$FREE_DISK" -lt 5000 ]; then
    echo -e "${YELLOW}Warning: Less than 5GB free disk space.${NC}"
    echo "  Ollama needs ~2GB, each model needs 2-8GB additional."
fi

# Install Ollama
echo -e "${YELLOW}[3/4]${NC} Installing Ollama..."
if command -v ollama &>/dev/null; then
    echo -e "${GREEN}  Ollama is already installed!${NC}"
    ollama --version
else
    echo "  Downloading and running Ollama installer..."
    curl -fsSL https://ollama.ai/install.sh | sh
    echo -e "${GREEN}  Ollama installed successfully!${NC}"
fi

# Start Ollama service
echo -e "${YELLOW}[4/4]${NC} Starting Ollama service..."
if ! pgrep -x "ollama" > /dev/null; then
    ollama serve &>/dev/null &
    sleep 2
    echo -e "${GREEN}  Ollama service started${NC}"
else
    echo -e "${GREEN}  Ollama service already running${NC}"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Ollama is ready!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  Quick start commands:"
echo ""
echo "    ollama pull llama3.2        # Download Llama 3.2 (2GB)"
echo "    ollama pull phi3            # Download Phi-3 (2.3GB)"
echo "    ollama pull mistral         # Download Mistral (4.1GB)"
echo "    ollama pull codellama       # Download CodeLlama (3.8GB)"
echo "    ollama pull llama3.2:1b     # Download tiny 1B model (700MB)"
echo ""
echo "    ollama run llama3.2         # Chat with Llama 3.2"
echo "    ollama list                 # List downloaded models"
echo "    ollama rm <model>           # Remove a model"
echo ""
echo "  API available at: http://localhost:11434"
echo ""

# Optionally download a starter model
if [ "$1" = "--with-model" ]; then
    echo -e "${YELLOW}Downloading starter model (llama3.2:1b - smallest, ~700MB)...${NC}"
    echo "This may take a few minutes depending on your internet speed."
    ollama pull llama3.2:1b
    echo ""
    echo -e "${GREEN}Model ready! Run: ollama run llama3.2:1b${NC}"
fi
