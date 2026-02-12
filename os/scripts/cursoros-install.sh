#!/bin/bash
# ============================================================================
# CursorOS - Friendly Package Installer
# ============================================================================
# A user-friendly wrapper around apt that makes installing software easy.
#
# Usage:
#   cursoros-install <package>       # Install a package
#   cursoros-install --search <q>    # Search for packages
#   cursoros-install --list          # List installed packages
#   cursoros-install --remove <pkg>  # Remove a package
#   cursoros-install --popular       # Show popular packages
# ============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_popular() {
    echo -e "${CYAN}=== Popular Packages ===${NC}"
    echo ""
    echo -e "${GREEN}  AI / Machine Learning:${NC}"
    echo "    install-ollama         - Ollama (local AI models)"
    echo "    python3-pip            - Python package manager"
    echo ""
    echo -e "${GREEN}  Development:${NC}"
    echo "    build-essential        - GCC, Make, etc."
    echo "    nodejs npm             - Node.js runtime"
    echo "    python3 python3-venv   - Python 3"
    echo "    golang                 - Go programming language"
    echo "    rustc cargo            - Rust programming language"
    echo "    docker.io              - Docker containers"
    echo "    git                    - Version control"
    echo "    code                   - VS Code (use snap or .deb)"
    echo ""
    echo -e "${GREEN}  Browsers:${NC}"
    echo "    firefox-esr            - Firefox (pre-installed)"
    echo "    chromium               - Chromium browser"
    echo ""
    echo -e "${GREEN}  Multimedia:${NC}"
    echo "    vlc                    - VLC media player"
    echo "    gimp                   - Image editor"
    echo "    audacity               - Audio editor"
    echo "    obs-studio             - Screen recording"
    echo ""
    echo -e "${GREEN}  Office:${NC}"
    echo "    libreoffice            - Office suite"
    echo ""
    echo -e "${GREEN}  Gaming:${NC}"
    echo "    steam                  - Steam client"
    echo ""
    echo -e "${GREEN}  Utilities:${NC}"
    echo "    neofetch               - System info (pre-installed)"
    echo "    htop                   - Process viewer (pre-installed)"
    echo "    tmux                   - Terminal multiplexer"
    echo "    ranger                 - Terminal file manager"
    echo ""
    echo "  Install any package: cursoros-install <package-name>"
}

if [ $# -eq 0 ]; then
    echo -e "${CYAN}CursorOS Package Installer${NC}"
    echo ""
    echo "Usage:"
    echo "  cursoros-install <package>       - Install a package"
    echo "  cursoros-install --search <q>    - Search packages"
    echo "  cursoros-install --list          - List installed"
    echo "  cursoros-install --remove <pkg>  - Remove a package"
    echo "  cursoros-install --popular       - Show popular packages"
    exit 0
fi

case "$1" in
    --search|-s)
        shift
        echo -e "${CYAN}Searching for '$1'...${NC}"
        apt search "$1" 2>/dev/null
        ;;
    --list|-l)
        echo -e "${CYAN}Installed packages:${NC}"
        dpkg --get-selections | grep -v deinstall | awk '{print "  " $1}'
        ;;
    --remove|-r)
        shift
        echo -e "${YELLOW}Removing $1...${NC}"
        sudo apt remove -y "$1"
        echo -e "${GREEN}Done.${NC}"
        ;;
    --popular|-p)
        show_popular
        ;;
    --help|-h)
        echo "Usage: cursoros-install [--search|--list|--remove|--popular] [package]"
        ;;
    *)
        echo -e "${CYAN}Installing: $@${NC}"
        echo ""
        sudo apt update -qq
        sudo apt install -y "$@"
        echo ""
        echo -e "${GREEN}Installation complete!${NC}"
        ;;
esac
