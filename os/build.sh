#!/bin/bash
# ============================================================================
# CursorOS v3.0 "Horizon" - Premium Desktop ISO Builder
# ============================================================================
# Builds a ~6GB bootable ISO comparable to macOS / Windows in features and
# polish. Includes a full graphical desktop with macOS-inspired theming,
# a web browser, office suite, media players, image editor, an app store,
# printing, Bluetooth, and Ollama AI support.
#
# Usage: sudo ./build.sh [--clean] [--skip-themes]
# ============================================================================

set -e

# ============================================================================
# Configuration
# ============================================================================
OS_NAME="CursorOS"
OS_VERSION="3.0.0"
OS_CODENAME="Horizon"
DEBIAN_SUITE="bookworm"
ARCH="amd64"
BUILD_DIR="$(pwd)/build-distro"
ROOTFS_DIR="${BUILD_DIR}/rootfs"
ISO_DIR="${BUILD_DIR}/iso"
OUTPUT_ISO="${OS_NAME}-${OS_VERSION}-${ARCH}.iso"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${CYAN}══════════ $1 ══════════${NC}\n"; }

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
# Phase 0: Build Dependencies
# ============================================================================
install_build_deps() {
    log_section "Phase 0: Build Dependencies"
    apt-get update -qq
    apt-get install -y -qq \
        debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin \
        grub-common mtools dosfstools isolinux syslinux-utils \
        wget curl rsync git
    log_info "Build dependencies installed."
}

# ============================================================================
# Phase 1: Bootstrap
# ============================================================================
bootstrap_rootfs() {
    log_section "Phase 1: Bootstrap Debian ${DEBIAN_SUITE}"
    [ -d "${ROOTFS_DIR}" ] && { cleanup; rm -rf "${ROOTFS_DIR}"; }
    mkdir -p "${ROOTFS_DIR}"
    debootstrap --arch="${ARCH}" --variant=minbase \
        --include=apt,apt-utils,locales,sudo,systemd,systemd-sysv,dbus,ca-certificates,gnupg \
        "${DEBIAN_SUITE}" "${ROOTFS_DIR}" http://deb.debian.org/debian
    log_info "Base system bootstrapped."
}

# ============================================================================
# Phase 2: Configure Base
# ============================================================================
configure_base() {
    log_section "Phase 2: Configure Base System"
    mount --bind /dev "${ROOTFS_DIR}/dev"
    mount --bind /dev/pts "${ROOTFS_DIR}/dev/pts"
    mount -t proc proc "${ROOTFS_DIR}/proc"
    mount -t sysfs sys "${ROOTFS_DIR}/sys"
    mount -t tmpfs tmpfs "${ROOTFS_DIR}/run"

    cat > "${ROOTFS_DIR}/etc/apt/sources.list" <<EOF
deb http://deb.debian.org/debian ${DEBIAN_SUITE} main contrib non-free non-free-firmware
deb http://deb.debian.org/debian ${DEBIAN_SUITE}-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security ${DEBIAN_SUITE}-security main contrib non-free non-free-firmware
EOF

    echo "cursoros" > "${ROOTFS_DIR}/etc/hostname"
    cat > "${ROOTFS_DIR}/etc/hosts" <<EOF
127.0.0.1   localhost cursoros
::1         localhost ip6-localhost ip6-loopback
EOF

    chroot "${ROOTFS_DIR}" bash -c "
        echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
        locale-gen
        update-locale LANG=en_US.UTF-8
        ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    "
    log_info "Base configured."
}

# ============================================================================
# Phase 3: Install ALL Packages
# ============================================================================
install_packages() {
    log_section "Phase 3: Install Software (this is the big one)"
    chroot "${ROOTFS_DIR}" apt-get update -qq

    # ---------- Linux Kernel + Firmware ----------
    log_info "[3.1] Linux kernel + firmware..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        linux-image-amd64 linux-headers-amd64 \
        firmware-linux-free firmware-linux-nonfree firmware-misc-nonfree \
        firmware-realtek firmware-iwlwifi firmware-atheros \
        firmware-sof-signed \
        intel-microcode amd64-microcode \
        2>/dev/null || log_warn "Some firmware packages unavailable (non-critical)"

    # ---------- Display Server + Compositor ----------
    log_info "[3.2] X.Org + compositor..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        xorg xserver-xorg xserver-xorg-video-all xserver-xorg-input-all \
        picom

    # ---------- XFCE4 Desktop Environment ----------
    log_info "[3.3] XFCE4 desktop environment..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        xfce4 xfce4-goodies \
        xfce4-whiskermenu-plugin xfce4-weather-plugin \
        xfce4-clipman-plugin xfce4-datetime-plugin \
        xfce4-places-plugin \
        xfce4-pulseaudio-plugin xfce4-power-manager \
        lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
        menulibre

    # ---------- Plank Dock (macOS-like) ----------
    log_info "[3.4] Plank dock..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq plank

    # ---------- Themes + Icons (Premium Look) ----------
    log_info "[3.5] Premium themes and icons..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        papirus-icon-theme \
        arc-theme \
        breeze-cursor-theme \
        gtk2-engines-murrine gtk2-engines-pixbuf \
        adwaita-icon-theme-full \
        fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-noto-mono \
        fonts-liberation fonts-dejavu-core fonts-firacode \
        fonts-roboto fonts-ubuntu \
        dmz-cursor-theme \
        2>/dev/null || log_warn "Some theme/font packages unavailable"

    # ---------- Web Browser ----------
    log_info "[3.6] Firefox ESR..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq firefox-esr

    # ---------- Office Suite ----------
    log_info "[3.7] LibreOffice suite..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        libreoffice-calc libreoffice-writer libreoffice-impress \
        libreoffice-draw libreoffice-math \
        libreoffice-gtk3 libreoffice-gnome

    # ---------- Graphics / Image Editing ----------
    log_info "[3.8] Graphics software..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        gimp gimp-data-extras \
        inkscape \
        ristretto \
        shotwell \
        simple-scan \
        drawing \
        2>/dev/null || log_warn "Some graphics packages unavailable"

    # ---------- Multimedia ----------
    log_info "[3.9] Multimedia (VLC, codecs, audio)..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        vlc vlc-plugin-base \
        parole \
        celluloid \
        cheese \
        pulseaudio pavucontrol alsa-utils \
        gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-ugly gstreamer1.0-plugins-bad \
        gstreamer1.0-libav \
        ffmpeg \
        2>/dev/null || log_warn "Some multimedia packages unavailable"

    # ---------- Networking ----------
    log_info "[3.10] Networking (WiFi, Bluetooth, VPN)..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        network-manager network-manager-gnome network-manager-openvpn \
        network-manager-openvpn-gnome \
        wpasupplicant wireless-tools rfkill iw \
        bluez bluez-tools blueman \
        iputils-ping net-tools traceroute dnsutils whois nmap \
        wget curl ca-certificates openssh-client \
        transmission-gtk

    # ---------- Printing ----------
    log_info "[3.11] Printing support (CUPS)..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        cups cups-browsed cups-bsd cups-client cups-filters \
        system-config-printer printer-driver-all \
        hplip \
        2>/dev/null || log_warn "Some printer drivers unavailable"

    # ---------- System Utilities ----------
    log_info "[3.12] System utilities..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        bash-completion htop btop neofetch \
        nano vim-tiny micro \
        git git-gui gitk \
        unzip zip p7zip-full xarchiver \
        gparted gnome-disk-utility baobab \
        synaptic \
        software-properties-common apt-transport-https \
        lsb-release policykit-1 \
        gvfs gvfs-backends gvfs-fuse \
        udisks2 upower acpi acpid \
        dkms build-essential \
        gnome-calculator \
        gnome-calendar \
        gnome-clocks \
        evince \
        catfish \
        xdg-utils xdg-user-dirs xdg-user-dirs-gtk \
        gnome-keyring seahorse \
        timeshift \
        redshift redshift-gtk \
        flameshot \
        numlockx \
        xclip xsel \
        inxi lshw hwinfo pciutils usbutils \
        dconf-cli dconf-editor \
        flatpak \
        at-spi2-core \
        file \
        man-db \
        less

    # ---------- App Store (GNOME Software + Flatpak) ----------
    log_info "[3.13] App store (GNOME Software)..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        gnome-software gnome-software-plugin-flatpak \
        2>/dev/null || log_warn "GNOME Software install issue (non-critical)"

    # ---------- Development Tools ----------
    log_info "[3.14] Development tools..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        python3 python3-pip python3-venv python3-dev \
        gcc g++ make cmake \
        nodejs npm \
        default-jdk-headless \
        2>/dev/null || log_warn "Some dev packages unavailable"

    # ---------- Plymouth Boot Splash ----------
    log_info "[3.15] Plymouth boot splash..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        plymouth plymouth-themes

    # ---------- Live System ----------
    log_info "[3.16] Live boot support..."
    chroot "${ROOTFS_DIR}" apt-get install -y -qq \
        live-boot live-config live-config-systemd rsync

    # ---------- CRITICAL: Rebuild initramfs with live-boot hooks ----------
    log_info "[3.17] Rebuilding initramfs (includes live-boot hooks)..."
    chroot "${ROOTFS_DIR}" update-initramfs -u -k all
    # Verify live-boot is in the initramfs
    chroot "${ROOTFS_DIR}" bash -c '
        INITRD=$(ls /boot/initrd.img-* 2>/dev/null | sort -V | tail -1)
        if [ -n "$INITRD" ]; then
            if lsinitramfs "$INITRD" 2>/dev/null | grep -q "live"; then
                echo "VERIFIED: live-boot hooks present in initramfs"
            else
                echo "WARNING: live-boot hooks NOT found, forcing rebuild..."
                update-initramfs -c -k all
            fi
        fi
    '

    # ---------- Cleanup ----------
    log_info "Cleaning apt cache..."
    chroot "${ROOTFS_DIR}" apt-get clean
    chroot "${ROOTFS_DIR}" rm -rf /var/lib/apt/lists/*
    log_info "All packages installed."
}

# ============================================================================
# Phase 4: Install Premium Theme (WhiteSur - macOS-inspired)
# ============================================================================
install_premium_theme() {
    log_section "Phase 4: Install Premium macOS-inspired Theme"

    chroot "${ROOTFS_DIR}" bash -c '
        set -e
        cd /tmp

        # --- WhiteSur GTK Theme (macOS Big Sur inspired) ---
        echo "Downloading WhiteSur GTK theme..."
        git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git 2>/dev/null || true
        if [ -d WhiteSur-gtk-theme ]; then
            cd WhiteSur-gtk-theme
            bash install.sh -c Dark -t default -l --tweaks solid -d /usr/share/themes 2>/dev/null || \
            bash install.sh -d /usr/share/themes 2>/dev/null || true
            cd /tmp
            rm -rf WhiteSur-gtk-theme
            echo "WhiteSur GTK theme installed."
        fi

        # --- WhiteSur Icon Theme ---
        echo "Downloading WhiteSur icon theme..."
        git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git 2>/dev/null || true
        if [ -d WhiteSur-icon-theme ]; then
            cd WhiteSur-icon-theme
            bash install.sh -d /usr/share/icons 2>/dev/null || true
            cd /tmp
            rm -rf WhiteSur-icon-theme
            echo "WhiteSur icon theme installed."
        fi

        # --- WhiteSur Cursor Theme ---
        echo "Downloading WhiteSur cursor theme..."
        git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git 2>/dev/null || true
        if [ -d WhiteSur-cursors ]; then
            cd WhiteSur-cursors
            bash install.sh 2>/dev/null || {
                mkdir -p /usr/share/icons/WhiteSur-cursors
                cp -r dist/* /usr/share/icons/WhiteSur-cursors/ 2>/dev/null || true
            }
            cd /tmp
            rm -rf WhiteSur-cursors
            echo "WhiteSur cursor theme installed."
        fi

        # Clean git cache
        rm -rf /tmp/.git* 2>/dev/null || true
    '
    log_info "Premium themes installed."
}

# ============================================================================
# Phase 5: Users + Auto-login
# ============================================================================
configure_users() {
    log_section "Phase 5: Configure Users"
    chroot "${ROOTFS_DIR}" bash -c "
        useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,bluetooth,cdrom,lpadmin,scanner cursor 2>/dev/null || true
        echo 'cursor:cursor' | chpasswd
        echo 'root:root' | chpasswd
    "

    cat > "${ROOTFS_DIR}/etc/sudoers.d/cursor" <<EOF
cursor ALL=(ALL) NOPASSWD: ALL
EOF
    chmod 440 "${ROOTFS_DIR}/etc/sudoers.d/cursor"

    mkdir -p "${ROOTFS_DIR}/etc/lightdm"
    cat > "${ROOTFS_DIR}/etc/lightdm/lightdm.conf" <<EOF
[Seat:*]
autologin-user=cursor
autologin-user-timeout=0
user-session=xfce
greeter-session=lightdm-gtk-greeter
greeter-hide-users=false
EOF

    # Create XDG user directories
    chroot "${ROOTFS_DIR}" bash -c "
        su - cursor -c 'xdg-user-dirs-update' 2>/dev/null || true
    "

    log_info "Users configured."
}

# ============================================================================
# Phase 6: Apply CursorOS Branding & Configuration
# ============================================================================
apply_branding() {
    log_section "Phase 6: Apply CursorOS Branding"

    # --- Copy all overlay files ---
    if [ -d "${SCRIPT_DIR}/includes" ]; then
        rsync -a "${SCRIPT_DIR}/includes/" "${ROOTFS_DIR}/"
    fi

    # --- Copy to actual user home (not just skel) ---
    rsync -a "${ROOTFS_DIR}/etc/skel/" "${ROOTFS_DIR}/home/cursor/"

    # --- Generate Premium Wallpaper ---
    log_info "Generating CursorOS wallpapers..."
    chroot "${ROOTFS_DIR}" bash -c "
        apt-get update -qq && apt-get install -y -qq imagemagick 2>/dev/null || true
        if command -v convert &>/dev/null; then
            mkdir -p /usr/share/backgrounds

            # --- Main wallpaper: deep gradient with subtle branding ---
            convert -size 3840x2160 \\
                \( -size 3840x2160 gradient:'#0d1117'-'#161b22' -rotate 135 \) \\
                \( -size 3840x2160 xc:none \\
                   -fill 'rgba(0,212,255,0.03)' \\
                   -draw 'circle 1920,800 1920,1600' \\
                   -fill 'rgba(139,92,246,0.03)' \\
                   -draw 'circle 2800,1400 2800,2000' \\
                   -fill 'rgba(236,72,153,0.02)' \\
                   -draw 'circle 900,1600 900,2100' \\
                \) -composite \\
                /usr/share/backgrounds/cursoros-dark.png 2>/dev/null || \\
            convert -size 3840x2160 xc:'#0d1117' /usr/share/backgrounds/cursoros-dark.png

            # --- Light wallpaper variant ---
            convert -size 3840x2160 \\
                gradient:'#e8eaed'-'#c4c7cc' \\
                -rotate 135 \\
                /usr/share/backgrounds/cursoros-light.png 2>/dev/null || \\
            convert -size 3840x2160 xc:'#e8eaed' /usr/share/backgrounds/cursoros-light.png

            # --- Accent wallpaper ---
            convert -size 3840x2160 \\
                \( -size 3840x2160 gradient:'#0a192f'-'#112240' -rotate 135 \) \\
                \( -size 3840x2160 xc:none \\
                   -fill 'rgba(100,255,218,0.04)' \\
                   -draw 'circle 2400,900 2400,1800' \\
                \) -composite \\
                /usr/share/backgrounds/cursoros-ocean.png 2>/dev/null || \\
            convert -size 3840x2160 xc:'#0a192f' /usr/share/backgrounds/cursoros-ocean.png

            # --- Default wallpaper symlink ---
            ln -sf /usr/share/backgrounds/cursoros-dark.png /usr/share/backgrounds/cursoros-wallpaper.png

            apt-get remove -y -qq imagemagick 2>/dev/null || true
            apt-get autoremove -y -qq 2>/dev/null || true
        fi
    "

    # --- OS Release ---
    cat > "${ROOTFS_DIR}/etc/os-release" <<EOF
PRETTY_NAME="${OS_NAME} ${OS_VERSION} (${OS_CODENAME})"
NAME="${OS_NAME}"
VERSION_ID="${OS_VERSION}"
VERSION="${OS_VERSION} (${OS_CODENAME})"
ID=cursoros
ID_LIKE=debian
HOME_URL="https://github.com/emailinuse804-png/emailinuse804-png.github.io"
BUG_REPORT_URL="https://github.com/emailinuse804-png/emailinuse804-png.github.io/issues"
SUPPORT_URL="https://github.com/emailinuse804-png/emailinuse804-png.github.io"
EOF

    cat > "${ROOTFS_DIR}/etc/lsb-release" <<EOF
DISTRIB_ID=${OS_NAME}
DISTRIB_RELEASE=${OS_VERSION}
DISTRIB_CODENAME=${OS_CODENAME}
DISTRIB_DESCRIPTION="${OS_NAME} ${OS_VERSION} (${OS_CODENAME})"
EOF

    # --- Login Screen ---
    cat > "${ROOTFS_DIR}/etc/lightdm/lightdm-gtk-greeter.conf" <<'EOF'
[greeter]
background=/usr/share/backgrounds/cursoros-dark.png
theme-name=WhiteSur-Dark
icon-theme-name=WhiteSur-dark
font-name=Noto Sans 11
cursor-theme-name=WhiteSur-cursors
cursor-theme-size=24
indicators=~host;~spacer;~session;~language;~a11y;~clock;~power
clock-format=%a %b %d  %H:%M
panel-position=top
position=50%,center 50%,center
screen-reader=false
xft-antialias=true
xft-dpi=96
xft-hintstyle=hintslight
xft-rgba=rgb
EOF

    # --- Issue / MOTD ---
    cat > "${ROOTFS_DIR}/etc/issue" <<EOF

     ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗  ██████╗ ███████╗
    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗██╔═══██╗██╔════╝
    ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝██║   ██║███████╗
    ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗██║   ██║╚════██║
    ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║╚██████╔╝███████║
     ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝

    ${OS_NAME} ${OS_VERSION} "${OS_CODENAME}" — \\n \\l

EOF

    cat > "${ROOTFS_DIR}/etc/motd" <<EOF

  Welcome to CursorOS ${OS_VERSION} "${OS_CODENAME}"
  ─────────────────────────────────
  Type 'cursoros-help' for commands
  Type 'install-ollama' for AI

EOF

    # --- Flatpak remote ---
    chroot "${ROOTFS_DIR}" bash -c "
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    "

    # --- Fix ownership ---
    chroot "${ROOTFS_DIR}" chown -R 1000:1000 /home/cursor/ 2>/dev/null || true

    log_info "Branding applied."
}

# ============================================================================
# Phase 7: Plymouth Boot Splash
# ============================================================================
install_plymouth_theme() {
    log_section "Phase 7: Plymouth Boot Splash"

    THEME_DIR="${ROOTFS_DIR}/usr/share/plymouth/themes/cursoros"
    mkdir -p "${THEME_DIR}"

    cat > "${THEME_DIR}/cursoros.plymouth" <<'EOF'
[Plymouth Theme]
Name=CursorOS
Description=CursorOS boot splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/cursoros
ScriptFile=/usr/share/plymouth/themes/cursoros/cursoros.script
EOF

    cat > "${THEME_DIR}/cursoros.script" <<'PLYSCRIPT'
// CursorOS Plymouth Boot Splash - Animated spinner with logo text

Window.SetBackgroundTopColor(0.05, 0.07, 0.09);
Window.SetBackgroundBottomColor(0.08, 0.10, 0.13);

// Centered status text
message_sprite = Sprite();
fun message_callback(text) {
    my_image = Image.Text(text, 0.63, 0.68, 0.75, 1, "Noto Sans 14");
    message_sprite.SetImage(my_image);
    message_sprite.SetX(Window.GetWidth() / 2 - my_image.GetWidth() / 2);
    message_sprite.SetY(Window.GetHeight() * 0.65);
}
Plymouth.SetMessageFunction(message_callback);

// Title text
title_image = Image.Text("CursorOS", 0.00, 0.83, 1.00, 1, "Noto Sans Bold 42");
title_sprite = Sprite(title_image);
title_sprite.SetX(Window.GetWidth() / 2 - title_image.GetWidth() / 2);
title_sprite.SetY(Window.GetHeight() * 0.40);

// Subtitle
sub_image = Image.Text("Horizon", 0.50, 0.55, 0.60, 1, "Noto Sans 16");
sub_sprite = Sprite(sub_image);
sub_sprite.SetX(Window.GetWidth() / 2 - sub_image.GetWidth() / 2);
sub_sprite.SetY(Window.GetHeight() * 0.40 + title_image.GetHeight() + 8);

// Spinner dots
NUM_DOTS = 8;
dot_sprites = [];
dot_angle = 0;

for (i = 0; i < NUM_DOTS; i++) {
    dot_sprites[i] = Sprite();
    dot_image = Image.Text("●", 0.00, 0.83 * (i / NUM_DOTS), 1.00 * (i / NUM_DOTS + 0.3), 1, "Noto Sans 12");
    dot_sprites[i].SetImage(dot_image);
}

fun refresh_callback() {
    dot_angle += 0.05;
    cx = Window.GetWidth() / 2;
    cy = Window.GetHeight() * 0.58;
    for (i = 0; i < NUM_DOTS; i++) {
        a = dot_angle + i * (2 * 3.14159 / NUM_DOTS);
        dx = Math.Cos(a) * 30;
        dy = Math.Sin(a) * 30;
        dot_sprites[i].SetX(cx + dx - 4);
        dot_sprites[i].SetY(cy + dy - 4);
        dot_sprites[i].SetOpacity(0.3 + 0.7 * (i / NUM_DOTS));
    }
}
Plymouth.SetRefreshFunction(refresh_callback);

// Password prompt
fun display_password_callback(prompt, bullets) {
    pwd_image = Image.Text(prompt, 0.63, 0.68, 0.75, 1, "Noto Sans 14");
    message_sprite.SetImage(pwd_image);
    message_sprite.SetX(Window.GetWidth() / 2 - pwd_image.GetWidth() / 2);
    message_sprite.SetY(Window.GetHeight() * 0.70);
}
Plymouth.SetDisplayPasswordFunction(display_password_callback);
PLYSCRIPT

    # Set as default Plymouth theme
    chroot "${ROOTFS_DIR}" bash -c "
        plymouth-set-default-theme cursoros 2>/dev/null || true
        update-initramfs -u 2>/dev/null || true
    "

    log_info "Plymouth boot splash installed."
}

# ============================================================================
# Phase 8: Install Custom Scripts
# ============================================================================
install_scripts() {
    log_section "Phase 8: Install CursorOS Scripts"
    if [ -d "${SCRIPT_DIR}/scripts" ]; then
        for script in "${SCRIPT_DIR}/scripts"/*.sh; do
            [ -f "$script" ] || continue
            name=$(basename "$script" .sh)
            cp "$script" "${ROOTFS_DIR}/usr/local/bin/${name}"
            chmod +x "${ROOTFS_DIR}/usr/local/bin/${name}"
            log_info "  → ${name}"
        done
    fi
    cp -r "${SCRIPT_DIR}/includes/usr/share/applications/"* \
          "${ROOTFS_DIR}/usr/share/applications/" 2>/dev/null || true
    log_info "Scripts installed."
}

# ============================================================================
# Phase 9: Configure Services
# ============================================================================
configure_services() {
    log_section "Phase 9: Configure Services"
    chroot "${ROOTFS_DIR}" bash -c "
        systemctl enable NetworkManager 2>/dev/null || true
        systemctl enable lightdm 2>/dev/null || true
        systemctl enable bluetooth 2>/dev/null || true
        systemctl enable cups 2>/dev/null || true
        systemctl enable acpid 2>/dev/null || true
        systemctl enable dbus 2>/dev/null || true
        systemctl disable apt-daily.timer 2>/dev/null || true
        systemctl disable apt-daily-upgrade.timer 2>/dev/null || true
    "

    cat > "${ROOTFS_DIR}/etc/NetworkManager/NetworkManager.conf" <<EOF
[main]
plugins=ifupdown,keyfile
dns=default

[ifupdown]
managed=true

[device]
wifi.scan-rand-mac-address=no
EOF

    # Enable Plymouth in GRUB
    mkdir -p "${ROOTFS_DIR}/etc/default"
    cat > "${ROOTFS_DIR}/etc/default/grub" <<'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="CursorOS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3"
GRUB_CMDLINE_LINUX=""
GRUB_GFXMODE=1920x1080
EOF

    log_info "Services configured."
}

# ============================================================================
# Phase 10: Build ISO
# ============================================================================
build_iso() {
    log_section "Phase 10: Build ISO Image"
    cleanup

    mkdir -p "${ISO_DIR}"/{boot/grub,live,EFI/BOOT}

    # Squashfs
    log_info "Compressing filesystem (this takes several minutes)..."
    rm -f "${ISO_DIR}/live/filesystem.squashfs"
    mksquashfs "${ROOTFS_DIR}" "${ISO_DIR}/live/filesystem.squashfs" \
        -comp xz -Xbcj x86 -b 1M -no-duplicates -no-recovery

    # Kernel + initrd
    log_info "Copying kernel..."
    VMLINUZ=$(ls "${ROOTFS_DIR}"/boot/vmlinuz-* 2>/dev/null | sort -V | tail -1)
    INITRD=$(ls "${ROOTFS_DIR}"/boot/initrd.img-* 2>/dev/null | sort -V | tail -1)
    [ -z "$VMLINUZ" ] || [ -z "$INITRD" ] && { log_error "Kernel not found!"; exit 1; }
    cp "$VMLINUZ" "${ISO_DIR}/boot/vmlinuz"
    cp "$INITRD" "${ISO_DIR}/boot/initrd.img"

    # GRUB config
    cat > "${ISO_DIR}/boot/grub/grub.cfg" <<'GRUBCFG'
set timeout=5
set default=0

insmod all_video
insmod gfxterm
insmod png

set gfxmode=1920x1080,1280x720,auto
terminal_output gfxterm

set color_normal=white/black
set color_highlight=cyan/black
set menu_color_normal=light-gray/black
set menu_color_highlight=white/dark-gray

menuentry "  CursorOS 3.0 — Start Desktop" --class cursoros --class os {
    linux /boot/vmlinuz boot=live quiet splash loglevel=3 \
        live-media-path=/live \
        username=cursor hostname=cursoros \
        locales=en_US.UTF-8 keyboard-layouts=us timezone=UTC
    initrd /boot/initrd.img
}

menuentry "  CursorOS 3.0 — Start Desktop (verbose)" --class cursoros {
    linux /boot/vmlinuz boot=live \
        live-media-path=/live \
        username=cursor hostname=cursoros \
        locales=en_US.UTF-8 keyboard-layouts=us timezone=UTC
    initrd /boot/initrd.img
}

menuentry "  CursorOS 3.0 — Safe Mode (no GPU driver)" --class cursoros {
    linux /boot/vmlinuz boot=live \
        live-media-path=/live nomodeset \
        username=cursor hostname=cursoros \
        locales=en_US.UTF-8 keyboard-layouts=us timezone=UTC \
        plymouth.enable=0
    initrd /boot/initrd.img
}

menuentry "  CursorOS 3.0 — Load to RAM (needs 6GB+)" --class cursoros {
    linux /boot/vmlinuz boot=live toram quiet splash \
        live-media-path=/live \
        username=cursor hostname=cursoros \
        locales=en_US.UTF-8 keyboard-layouts=us timezone=UTC
    initrd /boot/initrd.img
}

menuentry "  CursorOS 3.0 — Console Only" --class cursoros {
    linux /boot/vmlinuz boot=live \
        live-media-path=/live \
        username=cursor hostname=cursoros \
        locales=en_US.UTF-8 keyboard-layouts=us timezone=UTC \
        systemd.unit=multi-user.target
    initrd /boot/initrd.img
}
GRUBCFG

    # Build ISO
    log_info "Building ISO..."
    grub-mkrescue \
        --locales="" --themes="" \
        -o "${SCRIPT_DIR}/${OUTPUT_ISO}" \
        "${ISO_DIR}" -- -volid "CURSOROS" 2>/dev/null

    if [ -f "${SCRIPT_DIR}/${OUTPUT_ISO}" ]; then
        ISO_SIZE=$(du -h "${SCRIPT_DIR}/${OUTPUT_ISO}" | cut -f1)
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                                                      ║${NC}"
        echo -e "${GREEN}║   ${WHITE}CursorOS ${OS_VERSION} \"${OS_CODENAME}\" built successfully!${GREEN}         ║${NC}"
        echo -e "${GREEN}║                                                      ║${NC}"
        echo -e "${GREEN}║   ${CYAN}Output: ${OUTPUT_ISO} (${ISO_SIZE})${GREEN}              ║${NC}"
        echo -e "${GREEN}║                                                      ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "  QEMU:  qemu-system-x86_64 -cdrom ${OUTPUT_ISO} -m 4G -enable-kvm -smp 2 -vga virtio"
        echo "  USB:   sudo dd if=${OUTPUT_ISO} of=/dev/sdX bs=4M status=progress"
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
    echo -e "${CYAN}     ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗  ██████╗ ███████╗${NC}"
    echo -e "${CYAN}    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗██╔═══██╗██╔════╝${NC}"
    echo -e "${CYAN}    ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝██║   ██║███████╗${NC}"
    echo -e "${CYAN}    ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗██║   ██║╚════██║${NC}"
    echo -e "${CYAN}    ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║╚██████╔╝███████║${NC}"
    echo -e "${CYAN}     ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝${NC}"
    echo ""
    echo -e "  ${WHITE}${OS_NAME} v${OS_VERSION} \"${OS_CODENAME}\"${NC} — Premium Desktop ISO Builder"
    echo ""

    check_root

    if [ "$1" = "--clean" ]; then
        cleanup; rm -rf "${BUILD_DIR}"; rm -f "${SCRIPT_DIR}/${OUTPUT_ISO}"
        log_info "Cleaned."; exit 0
    fi

    START_TIME=$(date +%s)

    install_build_deps
    bootstrap_rootfs
    configure_base
    install_packages
    if [ "$1" != "--skip-themes" ]; then
        install_premium_theme
    fi
    configure_users
    apply_branding
    install_plymouth_theme
    install_scripts
    configure_services
    build_iso

    END_TIME=$(date +%s)
    ELAPSED=$(( END_TIME - START_TIME ))
    log_info "Total build time: $(( ELAPSED / 60 ))m $(( ELAPSED % 60 ))s"
}

main "$@"
