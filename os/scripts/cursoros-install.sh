#!/bin/bash
# CursorOS v3 - Friendly Package Installer

C='\033[38;5;39m'; G='\033[38;5;114m'; Y='\033[38;5;222m'
R='\033[38;5;203m'; D='\033[38;5;245m'; W='\033[1;37m'; N='\033[0m'

show_popular() {
    echo -e "\n  ${W}Popular Packages${N}\n"

    echo -e "  ${C}AI / Machine Learning${N}"
    echo -e "    ${G}install-ollama${N}         ${D}Ollama (local LLMs)${N}"
    echo -e "    ${G}python3-pip${N}            ${D}Python packages${N}"
    echo ""
    echo -e "  ${C}Development${N}"
    echo -e "    ${G}build-essential${N}         ${D}GCC, Make, etc.${N}"
    echo -e "    ${G}nodejs npm${N}              ${D}Node.js${N}"
    echo -e "    ${G}python3 python3-venv${N}    ${D}Python 3${N}"
    echo -e "    ${G}golang${N}                  ${D}Go language${N}"
    echo -e "    ${G}rustc cargo${N}             ${D}Rust language${N}"
    echo -e "    ${G}docker.io${N}               ${D}Docker containers${N}"
    echo ""
    echo -e "  ${C}Browsers${N}"
    echo -e "    ${G}chromium${N}                ${D}Chromium browser${N}"
    echo ""
    echo -e "  ${C}Multimedia${N}"
    echo -e "    ${G}obs-studio${N}              ${D}Screen recording${N}"
    echo -e "    ${G}audacity${N}                ${D}Audio editor${N}"
    echo -e "    ${G}kdenlive${N}                ${D}Video editor${N}"
    echo -e "    ${G}blender${N}                 ${D}3D modeling${N}"
    echo ""
    echo -e "  ${C}Productivity${N}"
    echo -e "    ${G}thunderbird${N}             ${D}Email client${N}"
    echo -e "    ${G}keepassxc${N}               ${D}Password manager${N}"
    echo -e "    ${G}syncthing${N}               ${D}File sync${N}"
    echo ""
    echo -e "  ${C}Gaming${N}"
    echo -e "    ${G}steam${N}                   ${D}Steam client${N}"
    echo -e "    ${G}lutris${N}                  ${D}Game launcher${N}"
    echo ""
    echo -e "  ${D}Or browse the App Store (GNOME Software) in the dock!${N}"
    echo ""
}

if [ $# -eq 0 ]; then
    echo -e "\n  ${W}CursorOS Package Installer${N}\n"
    echo -e "  ${Y}cursoros-install <package>${N}       Install"
    echo -e "  ${Y}cursoros-install --search <q>${N}    Search"
    echo -e "  ${Y}cursoros-install --list${N}          List installed"
    echo -e "  ${Y}cursoros-install --remove <pkg>${N}  Remove"
    echo -e "  ${Y}cursoros-install --popular${N}       Popular packages"
    echo ""; exit 0
fi

case "$1" in
    --search|-s) shift; echo -e "\n  ${C}Searching '$1'...${N}\n"; apt search "$1" 2>/dev/null ;;
    --list|-l) dpkg --get-selections | grep -v deinstall | awk '{print "  " $1}' | less ;;
    --remove|-r) shift; echo -e "  ${Y}Removing $1...${N}"; sudo apt remove -y "$1"; echo -e "  ${G}✓ Done${N}" ;;
    --popular|-p) show_popular ;;
    --help|-h) echo "Usage: cursoros-install [--search|--list|--remove|--popular] [package]" ;;
    *) echo -e "\n  ${C}Installing: $@${N}\n"; sudo apt update -qq && sudo apt install -y "$@" && echo -e "\n  ${G}✓ Done${N}\n" ;;
esac
