#!/bin/bash
# ============================================================================
# CursorOS - Help & Quick Reference
# ============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

echo ""
echo -e "${CYAN}  ______                           ____  _____${NC}"
echo -e "${CYAN} / ____/_  _______________  _____/ __ \\/ ___/${NC}"
echo -e "${CYAN}/ /   / / / / ___/ ___/ _ \\/ ___/ / / /\\__ \\ ${NC}"
echo -e "${CYAN}/ /___/ /_/ / /  (__  ) __/ /  / /_/ /___/ / ${NC}"
echo -e "${CYAN}\\____/\\__,_/_/  /____/\\___/_/   \\____//____/  ${NC}"
echo ""
echo -e "${WHITE}  CursorOS Quick Reference${NC}"
echo ""

echo -e "${GREEN}=== System ===${NC}"
echo "  sysinfo             - Show system info (neofetch)"
echo "  meminfo             - Show memory usage"
echo "  diskinfo            - Show disk usage"
echo "  htop                - Interactive process viewer"
echo "  cursoros-about       - About CursorOS"
echo ""

echo -e "${GREEN}=== Software Installation ===${NC}"
echo "  install-ollama       - Install Ollama AI platform"
echo "  install-ollama --with-model  - Install Ollama + download model"
echo "  cursoros-install <pkg>       - Install a package (apt wrapper)"
echo "  sudo apt install <pkg>       - Install via apt directly"
echo "  sudo apt search <query>      - Search for packages"
echo ""

echo -e "${GREEN}=== Networking ===${NC}"
echo "  nmtui               - Terminal network manager (WiFi setup)"
echo "  nm-applet           - GUI network applet (in taskbar)"
echo "  ip addr             - Show IP addresses"
echo "  ping <host>         - Test connectivity"
echo "  curl <url>          - Download/fetch URLs"
echo ""

echo -e "${GREEN}=== Desktop Shortcuts ===${NC}"
echo "  Ctrl+Alt+T          - Open terminal"
echo "  Alt+F2              - Run command dialog"
echo "  Super (Win) key     - Open application menu"
echo "  Ctrl+Alt+Del        - Task manager"
echo "  Alt+F4              - Close window"
echo "  Alt+Tab             - Switch windows"
echo ""

echo -e "${GREEN}=== File Management ===${NC}"
echo "  thunar              - File manager"
echo "  mousepad            - Text editor"
echo "  file-roller         - Archive manager"
echo ""

echo -e "${GREEN}=== Browser ===${NC}"
echo "  firefox-esr         - Firefox web browser"
echo ""

echo -e "${YELLOW}  Default user: cursor / password: cursor${NC}"
echo ""
