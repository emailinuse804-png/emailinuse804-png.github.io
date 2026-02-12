#!/bin/bash
# ============================================================================
# CursorOS - Linux Distribution Build Script
# ============================================================================
# Builds a bootable CursorOS ISO image based on Debian with:
#   - XFCE4 desktop environment (Windows-like layout)
#   - Firefox ESR web browser
#   - Full networking (Ethernet + WiFi)
#   - Software installation support (apt + curl + Ollama installer)
#   - Custom CursorOS branding throughout
#
# Usage: sudo ./build.sh [--clean] [--minimal]
#
# Requirements: Debian/Ubuntu host with ~10GB free disk space
# ============================================================================

set -e

# ============================================================================
# Configuration
# ============================================================================
OS_NAME="CursorOS"
OS_VERSION="2.0.0"
OS_CODENAME="Aurora"
DEBIAN_SUITE="bookworm"  # Debian 12
ARCH="amd64"
BUILD_DIR="$(pwd)/build-distro"
ROOTFS_DIR="${BUILD_DIR}/rootfs"
ISO_DIR="${BUILD_DIR}/iso"
OUTPUT_ISO="${OS_NAME}-${OS_VERSION}-${ARCH}.iso"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# Helper Functions
# ============================================================================
log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${CYAN}========== $1 ==========${NC}\n"; }

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

cleanup() {
    log_info "Cleaning up mounts..."
    umount -lf "${ROOTFS_DIR}/proc" 2>/dev/null || true
    umount -lf "${ROOTFS_DIR}/sys" 2>/dev/null || true
    umount -lf "${ROOTFS_DIR}/dev/pts" 2>/dev/null || true
    umount -lf "${ROOTFS_DIR}/dev" 2>/dev/null || true
    umount -lf "${ROOTFS_DIR}/run" 2>/dev/null || true
}

trap cleanup EXIT

# ============================================================================
# Phase 0: Prerequisites
# ============================================================================
install_build_deps() {
    log_section "Installing Build Dependencies"
    apt-get update -qq
    apt-get install -y -qq \
        debootstrap \
        squashfs-tools \
        xorriso \
        grub-pc-bin \
        grub-efi-amd64-bin \
        grub-common \
        mtools \
        dosfstools \
        isolinux \
        syslinux-utils \
        wget \
        curl \
        rsync
    log_info "Build dependencies installed."
}

# ============================================================================
# Phase 1: Bootstrap Base System
# ============================================================================
bootstrap_rootfs() {
    log_section "Bootstrapping Debian ${DEBIAN_SUITE} Root Filesystem"

    if [ -d "${ROOTFS_DIR}" ]; then
        log_warn "Existing rootfs found, removing..."
        cleanup
        rm -rf "${ROOTFS_DIR}"
    fi

    mkdir -p "${ROOTFS_DIR}"

    debootstrap \
        --arch="${ARCH}" \
        --variant=minbase \
        --include=apt,apt-utils,locales,sudo,systemd,systemd-sysv,dbus \
        "${DEBIAN_SUITE}" \
        "${ROOTFS_DIR}" \
        http://deb.debian.org/debian

    log_info "Base system bootstrapped."
}

# ============================================================================
# Phase 2: Configure Base System
# ============================================================================
configure_base() {
    log_section "Configuring Base System"

    # Mount virtual filesystems for chroot
    mount --bind /dev  "${ROOTFS_DIR}/dev"
    mount --bind /dev/pts "${ROOTFS_DIR}/dev/pts"
    mount -t proc proc "${ROOTFS_DIR}/proc"
    mount -t sysfs sys "${ROOTFS_DIR}/sys"
    mount -t tmpfs tmpfs "${ROOTFS_DIR}/run"

    # Configure apt sources
    cat > "${ROOTFS_DIR}/etc/apt/sources.list" <<EOF
deb http://deb.debian.org/debian ${DEBIAN_SUITE} main contrib non-free non-free-firmware
deb http://deb.debian.org/debian ${DEBIAN_SUITE}-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security ${DEBIAN_SUITE}-security main contrib non-free non-free-firmware
EOF

    # Set hostname
    echo "cursoros" > "${ROOTFS_DIR}/etc/hostname"
    cat > "${ROOTFS_DIR}/etc/hosts" <<EOF
127.0.0.1   localhost
127.0.1.1   cursoros
::1         localhost ip6-localhost ip6-loopback
EOF

    # Configure locale
    chroot "${ROOTFS_DIR}" bash -c "
        echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
        locale-gen
        update-locale LANG=en_US.UTF-8
    "

    # Set timezone
    chroot "${ROOTFS_DIR}" bash -c "
        ln -sf /usr/share/zoneinfo/UTC /etc/localtime
        echo 'UTC' > /etc/timezone
    "

    log_info "Base system configured."
}

# ============================================================================
# Phase 3: Install Packages
# ============================================================================
install_packages() {
    log_section "Installing Desktop & Application Packages"

    # Update package lists in chroot
    chroot "${ROOTFS_DIR}" apt-get update -qq

    # --- Linux Kernel ---
    log_info "Installing Linux kernel..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        linux-image-amd64 \
        linux-headers-amd64 \
        firmware-linux-free

    # --- XFCE4 Desktop Environment ---
    log_info "Installing XFCE4 desktop..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        xfce4 \
        xfce4-terminal \
        xfce4-whiskermenu-plugin \
        xfce4-taskmanager \
        xfce4-screenshooter \
        xfce4-power-manager \
        xfce4-notifyd \
        xfce4-pulseaudio-plugin \
        xfce4-clipman-plugin \
        thunar-archive-plugin \
        file-roller \
        mousepad \
        ristretto

    # --- Display Manager ---
    log_info "Installing display manager..."
    chroot "${ROOTFS_DIR}" bash -c "
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
            lightdm \
            lightdm-gtk-greeter \
            lightdm-gtk-greeter-settings
    "

    # --- X.Org Display Server ---
    log_info "Installing display server..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        xorg \
        xserver-xorg \
        xserver-xorg-video-all \
        xserver-xorg-input-all

    # --- Web Browser ---
    log_info "Installing Firefox ESR..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        firefox-esr

    # --- Networking ---
    log_info "Installing networking..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        network-manager \
        network-manager-gnome \
        wpasupplicant \
        wireless-tools \
        rfkill \
        iw \
        iputils-ping \
        net-tools \
        wget \
        curl \
        ca-certificates \
        gnupg

    # --- Audio ---
    log_info "Installing audio..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        pulseaudio \
        pavucontrol \
        alsa-utils

    # --- System Utilities ---
    log_info "Installing system utilities..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        bash-completion \
        htop \
        neofetch \
        nano \
        vim-tiny \
        git \
        unzip \
        zip \
        p7zip-full \
        gparted \
        gnome-disk-utility \
        synaptic \
        software-properties-common \
        apt-transport-https \
        lsb-release \
        policykit-1 \
        gvfs \
        gvfs-backends \
        udisks2 \
        upower \
        acpi \
        dkms \
        build-essential

    # --- Fonts ---
    log_info "Installing fonts..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        fonts-liberation \
        fonts-noto \
        fonts-noto-color-emoji \
        fonts-dejavu-core

    # --- Live System Tools ---
    log_info "Installing live system tools..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        live-boot \
        live-config \
        live-config-systemd \
        rsync

    # --- Firmware (for real hardware) ---
    log_info "Installing firmware packages..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        firmware-linux-nonfree \
        firmware-misc-nonfree \
        firmware-realtek \
        firmware-iwlwifi \
        firmware-atheros \
        2>/dev/null || log_warn "Some firmware packages not available (non-critical)"

    # --- Clean up ---
    chroot "${ROOTFS_DIR}" apt-get clean
    chroot "${ROOTFS_DIR}" rm -rf /var/lib/apt/lists/*

    log_info "All packages installed."
}

# ============================================================================
# Phase 4: Create User & Configure System
# ============================================================================
configure_users() {
    log_section "Configuring Users"

    # Create the default user
    chroot "${ROOTFS_DIR}" bash -c "
        useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,bluetooth,cdrom cursor 2>/dev/null || true
        echo 'cursor:cursor' | chpasswd
        echo 'root:root' | chpasswd
    "

    # Passwordless sudo for cursor user
    cat > "${ROOTFS_DIR}/etc/sudoers.d/cursor" <<EOF
cursor ALL=(ALL) NOPASSWD: ALL
EOF
    chmod 440 "${ROOTFS_DIR}/etc/sudoers.d/cursor"

    # Auto-login configuration for LightDM
    mkdir -p "${ROOTFS_DIR}/etc/lightdm"
    cat > "${ROOTFS_DIR}/etc/lightdm/lightdm.conf" <<EOF
[Seat:*]
autologin-user=cursor
autologin-user-timeout=0
user-session=xfce
greeter-session=lightdm-gtk-greeter
greeter-hide-users=false
EOF

    log_info "Users configured (user: cursor, password: cursor)."
}

# ============================================================================
# Phase 5: Apply CursorOS Branding
# ============================================================================
apply_branding() {
    log_section "Applying CursorOS Branding"

    # --- Copy all customization files ---
    if [ -d "${SCRIPT_DIR}/includes" ]; then
        log_info "Copying customization files..."
        rsync -a "${SCRIPT_DIR}/includes/" "${ROOTFS_DIR}/"
    fi

    # --- Generate Wallpaper ---
    log_info "Generating CursorOS wallpaper..."
    chroot "${ROOTFS_DIR}" bash -c "
        apt-get update -qq && apt-get install -y -qq imagemagick 2>/dev/null || true
        if command -v convert &>/dev/null; then
            convert -size 1920x1080 \
                -define gradient:angle=135 \
                gradient:'#0a0a2e'-'#1a1a4e' \
                -fill '#00d4ff' -font DejaVu-Sans-Bold -pointsize 72 \
                -gravity center -annotate +0-100 'CursorOS' \
                -fill '#8892b0' -font DejaVu-Sans -pointsize 24 \
                -gravity center -annotate +0-20 'v${OS_VERSION} \"${OS_CODENAME}\"' \
                -fill '#00d4ff33' -font DejaVu-Sans -pointsize 14 \
                -gravity south -annotate +0+40 'Built with Cursor AI' \
                /usr/share/backgrounds/cursoros-wallpaper.png 2>/dev/null && \
                echo 'Wallpaper generated.' || echo 'Wallpaper generation failed, using fallback.'

            # Also generate a simple fallback if the fancy one failed
            if [ ! -f /usr/share/backgrounds/cursoros-wallpaper.png ]; then
                convert -size 1920x1080 xc:'#0a0a2e' \
                    -fill '#00d4ff' -pointsize 72 \
                    -gravity center -annotate +0+0 'CursorOS' \
                    /usr/share/backgrounds/cursoros-wallpaper.png 2>/dev/null || true
            fi
            apt-get remove -y -qq imagemagick 2>/dev/null || true
            apt-get autoremove -y -qq 2>/dev/null || true
        fi
    "

    # --- OS Release Info ---
    cat > "${ROOTFS_DIR}/etc/os-release" <<EOF
PRETTY_NAME="${OS_NAME} ${OS_VERSION} (${OS_CODENAME})"
NAME="${OS_NAME}"
VERSION_ID="${OS_VERSION}"
VERSION="${OS_VERSION} (${OS_CODENAME})"
ID=cursoros
ID_LIKE=debian
HOME_URL="https://github.com/emailinuse804-png/emailinuse804-png.github.io"
BUG_REPORT_URL="https://github.com/emailinuse804-png/emailinuse804-png.github.io/issues"
EOF

    cat > "${ROOTFS_DIR}/etc/lsb-release" <<EOF
DISTRIB_ID=${OS_NAME}
DISTRIB_RELEASE=${OS_VERSION}
DISTRIB_CODENAME=${OS_CODENAME}
DISTRIB_DESCRIPTION="${OS_NAME} ${OS_VERSION} (${OS_CODENAME})"
EOF

    # --- Issue / MOTD ---
    cat > "${ROOTFS_DIR}/etc/issue" <<EOF

  ______                           ____  _____
 / ____/_  _______________  _____/ __ \\/ ___/
/ /   / / / / ___/ ___/ _ \\/ ___/ / / /\\__ \\
/ /___/ /_/ / /  (__  ) __/ /  / /_/ /___/ /
\\____/\\__,_/_/  /____/\\___/_/   \\____//____/

  ${OS_NAME} ${OS_VERSION} "${OS_CODENAME}" - \\n \\l

EOF

    cat > "${ROOTFS_DIR}/etc/motd" <<EOF

  Welcome to CursorOS ${OS_VERSION} "${OS_CODENAME}"!
  Built with Cursor AI

  Quick start:
    - Type 'install-ollama' to install Ollama AI
    - Type 'cursoros-help' for system commands
    - Default user: cursor / password: cursor

EOF

    # --- LightDM Greeter Branding ---
    mkdir -p "${ROOTFS_DIR}/etc/lightdm"
    cat > "${ROOTFS_DIR}/etc/lightdm/lightdm-gtk-greeter.conf" <<EOF
[greeter]
background=/usr/share/backgrounds/cursoros-wallpaper.png
theme-name=Adwaita-dark
icon-theme-name=Adwaita
font-name=Noto Sans 11
indicators=~host;~spacer;~session;~language;~a11y;~clock;~power
clock-format=%H:%M
panel-position=bottom
position=50%,center 50%,center
EOF

    # --- Neofetch Config ---
    mkdir -p "${ROOTFS_DIR}/home/cursor/.config/neofetch"
    cat > "${ROOTFS_DIR}/home/cursor/.config/neofetch/config.conf" <<EOF
print_info() {
    info title
    info underline
    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    info "DE" de
    info "WM" wm
    info "Terminal" term
    info "CPU" cpu
    info "GPU" gpu
    info "Memory" memory
    info "Disk" disk
    info "Local IP" local_ip
    info cols
}
ascii_distro="auto"
EOF

    # --- Custom Bash Profile ---
    cat > "${ROOTFS_DIR}/home/cursor/.bashrc" <<'BASHRC'
# CursorOS Bash Configuration
export PATH="/usr/local/bin:$PATH"

# Colors
export PS1='\[\033[01;32m\]\u@cursoros\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Aliases
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias sysinfo='neofetch'
alias diskinfo='df -h'
alias meminfo='free -h'
alias ports='sudo netstat -tlnp'

# Welcome message on first terminal
if [ -z "$CURSOROS_WELCOMED" ]; then
    export CURSOROS_WELCOMED=1
    echo ""
    echo -e "\033[36m  Welcome to CursorOS!\033[0m"
    echo -e "  Type \033[33m'cursoros-help'\033[0m for useful commands."
    echo ""
fi

# Enable bash completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi
BASHRC

    # Fix ownership
    chroot "${ROOTFS_DIR}" chown -R 1000:1000 /home/cursor/ 2>/dev/null || true

    log_info "Branding applied."
}

# ============================================================================
# Phase 6: Install Custom Scripts
# ============================================================================
install_scripts() {
    log_section "Installing CursorOS Scripts"

    # Copy scripts from the scripts directory
    if [ -d "${SCRIPT_DIR}/scripts" ]; then
        for script in "${SCRIPT_DIR}/scripts"/*.sh; do
            if [ -f "$script" ]; then
                name=$(basename "$script" .sh)
                cp "$script" "${ROOTFS_DIR}/usr/local/bin/${name}"
                chmod +x "${ROOTFS_DIR}/usr/local/bin/${name}"
                log_info "Installed script: ${name}"
            fi
        done
    fi

    # Copy desktop entries
    if [ -d "${SCRIPT_DIR}/includes/usr/share/applications" ]; then
        cp -r "${SCRIPT_DIR}/includes/usr/share/applications/"* \
              "${ROOTFS_DIR}/usr/share/applications/" 2>/dev/null || true
    fi

    log_info "Scripts installed."
}

# ============================================================================
# Phase 7: Configure Services
# ============================================================================
configure_services() {
    log_section "Configuring System Services"

    chroot "${ROOTFS_DIR}" bash -c "
        # Enable NetworkManager
        systemctl enable NetworkManager 2>/dev/null || true

        # Enable LightDM
        systemctl enable lightdm 2>/dev/null || true

        # Disable unnecessary services for live boot
        systemctl disable apt-daily.timer 2>/dev/null || true
        systemctl disable apt-daily-upgrade.timer 2>/dev/null || true

        # Enable DBUS
        systemctl enable dbus 2>/dev/null || true
    "

    # Configure NetworkManager
    cat > "${ROOTFS_DIR}/etc/NetworkManager/NetworkManager.conf" <<EOF
[main]
plugins=ifupdown,keyfile
dns=default

[ifupdown]
managed=true

[device]
wifi.scan-rand-mac-address=no
EOF

    log_info "Services configured."
}

# ============================================================================
# Phase 8: Build Squashfs & ISO
# ============================================================================
build_iso() {
    log_section "Building ISO Image"

    # Clean up chroot mounts
    cleanup

    # --- Create ISO directory structure ---
    mkdir -p "${ISO_DIR}"/{boot/grub,live,EFI/BOOT}

    # --- Create squashfs ---
    log_info "Creating squashfs filesystem (this takes a while)..."
    rm -f "${ISO_DIR}/live/filesystem.squashfs"
    mksquashfs "${ROOTFS_DIR}" "${ISO_DIR}/live/filesystem.squashfs" \
        -comp xz -Xbcj x86 -b 1M -no-duplicates -no-recovery \
        -e boot/vmlinuz* -e boot/initrd* 2>/dev/null

    # --- Copy kernel and initramfs ---
    log_info "Copying kernel and initramfs..."
    VMLINUZ=$(ls "${ROOTFS_DIR}"/boot/vmlinuz-* 2>/dev/null | sort -V | tail -1)
    INITRD=$(ls "${ROOTFS_DIR}"/boot/initrd.img-* 2>/dev/null | sort -V | tail -1)

    if [ -z "$VMLINUZ" ] || [ -z "$INITRD" ]; then
        log_error "Kernel or initramfs not found!"
        ls -la "${ROOTFS_DIR}/boot/"
        exit 1
    fi

    cp "$VMLINUZ" "${ISO_DIR}/boot/vmlinuz"
    cp "$INITRD" "${ISO_DIR}/boot/initrd.img"

    # --- GRUB Configuration ---
    cat > "${ISO_DIR}/boot/grub/grub.cfg" <<'GRUBCFG'
set timeout=5
set default=0

# CursorOS Theme
set color_normal=white/black
set color_highlight=cyan/black
set menu_color_normal=white/black
set menu_color_highlight=black/cyan

insmod all_video
insmod gfxterm
set gfxmode=auto
terminal_output gfxterm

menuentry "CursorOS 2.0 - Start Desktop" --class cursoros {
    linux /boot/vmlinuz boot=live toram quiet splash loglevel=3 \
        username=cursor hostname=cursoros \
        locales=en_US.UTF-8 keyboard-layouts=us \
        timezone=UTC
    initrd /boot/initrd.img
}

menuentry "CursorOS 2.0 - Safe Mode (no splash)" --class cursoros {
    linux /boot/vmlinuz boot=live toram \
        username=cursor hostname=cursoros \
        locales=en_US.UTF-8 keyboard-layouts=us \
        timezone=UTC nomodeset
    initrd /boot/initrd.img
}

menuentry "CursorOS 2.0 - RAM Mode (copy to RAM)" --class cursoros {
    linux /boot/vmlinuz boot=live toram=filesystem.squashfs quiet splash \
        username=cursor hostname=cursoros \
        locales=en_US.UTF-8 keyboard-layouts=us \
        timezone=UTC
    initrd /boot/initrd.img
}

menuentry "CursorOS 2.0 - Text Console" --class cursoros {
    linux /boot/vmlinuz boot=live toram \
        username=cursor hostname=cursoros \
        locales=en_US.UTF-8 keyboard-layouts=us \
        timezone=UTC systemd.unit=multi-user.target
    initrd /boot/initrd.img
}
GRUBCFG

    # --- Build BIOS bootable ISO ---
    log_info "Building ISO image..."
    grub-mkrescue \
        --locales="" \
        --themes="" \
        -o "${SCRIPT_DIR}/${OUTPUT_ISO}" \
        "${ISO_DIR}" \
        -- \
        -volid "CURSOROS" \
        2>/dev/null

    if [ -f "${SCRIPT_DIR}/${OUTPUT_ISO}" ]; then
        ISO_SIZE=$(du -h "${SCRIPT_DIR}/${OUTPUT_ISO}" | cut -f1)
        log_info ""
        echo -e "${GREEN}============================================${NC}"
        echo -e "${GREEN}  CursorOS ISO built successfully!${NC}"
        echo -e "${GREEN}  Output: ${OUTPUT_ISO} (${ISO_SIZE})${NC}"
        echo -e "${GREEN}============================================${NC}"
        echo ""
        echo "  Run with QEMU:"
        echo "    qemu-system-x86_64 -cdrom ${OUTPUT_ISO} -m 2G -enable-kvm -smp 2"
        echo ""
        echo "  Write to USB:"
        echo "    sudo dd if=${OUTPUT_ISO} of=/dev/sdX bs=4M status=progress"
        echo ""
    else
        log_error "ISO build failed!"
        exit 1
    fi
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo -e "${CYAN}  ______                           ____  _____${NC}"
    echo -e "${CYAN} / ____/_  _______________  _____/ __ \\/ ___/${NC}"
    echo -e "${CYAN}/ /   / / / / ___/ ___/ _ \\/ ___/ / / /\\__ \\ ${NC}"
    echo -e "${CYAN}/ /___/ /_/ / /  (__  ) __/ /  / /_/ /___/ / ${NC}"
    echo -e "${CYAN}\\____/\\__,_/_/  /____/\\___/_/   \\____//____/  ${NC}"
    echo ""
    echo -e "  ${OS_NAME} v${OS_VERSION} \"${OS_CODENAME}\" - ISO Builder"
    echo ""

    check_root

    if [ "$1" = "--clean" ]; then
        log_info "Cleaning build directory..."
        cleanup
        rm -rf "${BUILD_DIR}"
        rm -f "${SCRIPT_DIR}/${OUTPUT_ISO}"
        log_info "Clean complete."
        exit 0
    fi

    START_TIME=$(date +%s)

    install_build_deps
    bootstrap_rootfs
    configure_base
    install_packages
    configure_users
    apply_branding
    install_scripts
    configure_services
    build_iso

    END_TIME=$(date +%s)
    ELAPSED=$(( END_TIME - START_TIME ))
    MINUTES=$(( ELAPSED / 60 ))
    SECONDS=$(( ELAPSED % 60 ))
    log_info "Total build time: ${MINUTES}m ${SECONDS}s"
}

main "$@"
