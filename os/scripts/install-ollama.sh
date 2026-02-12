#!/bin/bash
# CursorOS v3 - Ollama AI Installer

C='\033[38;5;39m'; G='\033[38;5;114m'; Y='\033[38;5;222m'
R='\033[38;5;203m'; D='\033[38;5;245m'; W='\033[1;37m'; N='\033[0m'

echo ""
echo -e "  ${C}┌──────────────────────────────────────┐${N}"
echo -e "  ${C}│${N}  ${W}CursorOS — Ollama AI Installer${N}      ${C}│${N}"
echo -e "  ${C}└──────────────────────────────────────┘${N}"
echo ""

# Internet check
echo -e "  ${Y}[1/4]${N} Checking internet..."
if ! ping -c 1 -W 3 google.com &>/dev/null && ! ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
    echo -e "  ${R}No internet! Connect via the WiFi icon or run: nmtui${N}"
    exit 1
fi
echo -e "  ${G}✓${N} Connected"

# System check
echo -e "  ${Y}[2/4]${N} Checking system..."
RAM=$(free -m | awk '/^Mem:/{print $2}')
DISK=$(df -BM / | awk 'NR==2{print $4}' | tr -d 'M')
echo -e "  ${D}RAM: ${RAM}MB  |  Disk: ${DISK}MB free${N}"
[ "$RAM" -lt 2048 ] && echo -e "  ${Y}⚠ <2GB RAM — small models only${N}"
[ "$DISK" -lt 5000 ] && echo -e "  ${Y}⚠ <5GB disk — limited model storage${N}"

# Install
echo -e "  ${Y}[3/4]${N} Installing Ollama..."
if command -v ollama &>/dev/null; then
    echo -e "  ${G}✓${N} Already installed: $(ollama --version 2>&1)"
else
    curl -fsSL https://ollama.ai/install.sh | sh
    echo -e "  ${G}✓${N} Installed"
fi

# Start
echo -e "  ${Y}[4/4]${N} Starting Ollama service..."
if ! pgrep -x "ollama" > /dev/null; then
    ollama serve &>/dev/null &
    sleep 2
fi
echo -e "  ${G}✓${N} Running (API: http://localhost:11434)"

echo ""
echo -e "  ${W}Ready! Quick start:${N}"
echo ""
echo -e "    ${G}ollama pull llama3.2:1b${N}     ${D}Tiny model (700MB)${N}"
echo -e "    ${G}ollama pull llama3.2${N}         ${D}Llama 3.2 (2GB)${N}"
echo -e "    ${G}ollama pull phi3${N}             ${D}Phi-3 (2.3GB)${N}"
echo -e "    ${G}ollama pull codellama${N}        ${D}Code Llama (3.8GB)${N}"
echo -e "    ${G}ollama pull mistral${N}          ${D}Mistral 7B (4.1GB)${N}"
echo -e "    ${G}ollama pull deepseek-r1:8b${N}   ${D}DeepSeek R1 (4.7GB)${N}"
echo ""
echo -e "    ${G}ollama run llama3.2${N}          ${D}Start chatting${N}"
echo ""

if [ "$1" = "--with-model" ]; then
    echo -e "  ${Y}Downloading starter model (llama3.2:1b)...${N}"
    ollama pull llama3.2:1b
    echo -e "\n  ${G}✓${N} Model ready! Run: ${G}ollama run llama3.2:1b${N}"
fi
