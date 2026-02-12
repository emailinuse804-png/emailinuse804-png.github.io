#!/bin/bash
# CursorOS v3 "Horizon" - Help & Quick Reference

C='\033[38;5;39m'   # Cyan/blue
G='\033[38;5;114m'  # Green
Y='\033[38;5;222m'  # Yellow
W='\033[1;37m'      # White bold
D='\033[38;5;245m'  # Dim
N='\033[0m'         # Reset

echo ""
echo -e "${C}     ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗  ██████╗ ███████╗${N}"
echo -e "${C}    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗██╔═══██╗██╔════╝${N}"
echo -e "${C}    ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝██║   ██║███████╗${N}"
echo -e "${C}    ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗██║   ██║╚════██║${N}"
echo -e "${C}    ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║╚██████╔╝███████║${N}"
echo -e "${C}     ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝${N}"
echo -e "    ${D}v3.0 \"Horizon\" — Quick Reference${N}"
echo ""

echo -e "${W}  KEYBOARD SHORTCUTS${N}"
echo -e "  ${D}─────────────────────────────────────────${N}"
echo -e "  ${Y}Super${N}              Open App Menu"
echo -e "  ${Y}Super+Space${N}        App Finder (Spotlight)"
echo -e "  ${Y}Ctrl+Alt+T${N}         Terminal"
echo -e "  ${Y}Super+E${N}            File Manager"
echo -e "  ${Y}Super+B${N}            Browser"
echo -e "  ${Y}Super+I${N}            Settings"
echo -e "  ${Y}Super+L${N}            Lock Screen"
echo -e "  ${Y}Super+D${N}            Show Desktop"
echo -e "  ${Y}Super+Left/Right${N}   Tile Window"
echo -e "  ${Y}Super+Up${N}           Maximize"
echo -e "  ${Y}Super+F${N}            Fullscreen"
echo -e "  ${Y}Alt+Tab${N}            Switch Windows"
echo -e "  ${Y}Print${N}              Screenshot"
echo ""

echo -e "${W}  AI / OLLAMA${N}"
echo -e "  ${D}─────────────────────────────────────────${N}"
echo -e "  ${G}install-ollama${N}              Install Ollama"
echo -e "  ${G}install-ollama --with-model${N} Install + starter model"
echo -e "  ${G}ollama run llama3.2${N}         Chat with AI"
echo -e "  ${G}ollama pull codellama${N}       Download Code AI"
echo ""

echo -e "${W}  SOFTWARE${N}"
echo -e "  ${D}─────────────────────────────────────────${N}"
echo -e "  ${G}cursoros-install <pkg>${N}      Install package"
echo -e "  ${G}cursoros-install --popular${N}  Popular packages"
echo -e "  ${G}cursoros-install --search q${N} Search packages"
echo -e "  ${D}Or use the App Store (GNOME Software) in the dock${N}"
echo ""

echo -e "${W}  NETWORKING${N}"
echo -e "  ${D}─────────────────────────────────────────${N}"
echo -e "  ${G}nmtui${N}                      WiFi setup (terminal)"
echo -e "  ${D}Or click the WiFi icon in the top panel${N}"
echo -e "  ${G}myip${N}                       Show public IP"
echo ""

echo -e "${W}  SYSTEM${N}"
echo -e "  ${D}─────────────────────────────────────────${N}"
echo -e "  ${G}sysinfo${N}      neofetch     ${G}meminfo${N}   free -h"
echo -e "  ${G}diskinfo${N}     df -h        ${G}htop${N}      processes"
echo -e "  ${G}btop${N}         resource mon  ${G}update${N}    apt update"
echo ""

echo -e "  ${D}User: cursor / Password: cursor${N}"
echo ""
