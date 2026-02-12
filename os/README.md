# CursorOS

A premium desktop operating system built entirely with Cursor AI. macOS-inspired design, Windows-class feature set, and AI-ready out of the box.

## What is CursorOS?

CursorOS is a custom Linux distribution that delivers a polished desktop experience comparable to macOS and Windows. It boots from a USB drive or CD as a live system — no installation required — and comes pre-loaded with everything you need: a web browser, office suite, image editor, media player, app store, and one-command Ollama AI installation.

## Highlights

- **macOS-inspired Design** — WhiteSur dark theme, Plank dock with zoom hover, top menu bar, picom compositor with rounded corners, shadows, and transparency
- **Full Web Browser** — Firefox ESR with internet access out of the box
- **Office Suite** — LibreOffice Writer, Calc, Impress, Draw, Math
- **Image & Vector Editing** — GIMP and Inkscape
- **Media Playback** — VLC, Parole, full codec support (H.264, H.265, AAC, etc.)
- **App Store** — GNOME Software with Flatpak and Flathub
- **Printing & Bluetooth** — CUPS and Blueman
- **Ollama AI** — One command to install and run local LLMs
- **Networking** — WiFi, Ethernet, VPN (OpenVPN) via NetworkManager
- **~6 GB ISO** — comparable to a Windows install image

## Quick Start

```bash
# Build the ISO (requires Debian/Ubuntu + root)
cd os && sudo ./build.sh

# Run in QEMU
qemu-system-x86_64 -cdrom CursorOS-3.0.0-amd64.iso -m 4G -enable-kvm -smp 2 -vga virtio

# Write to USB
sudo dd if=CursorOS-3.0.0-amd64.iso of=/dev/sdX bs=4M status=progress
```

**Login:** `cursor` / `cursor` (auto-login enabled, passwordless sudo)

## Desktop

CursorOS uses a macOS-inspired layout:

| Element | Description |
|---------|-------------|
| **Top bar** | App menu, folder shortcuts, centered clock, system tray (WiFi, Bluetooth, volume, battery, notifications) |
| **Plank dock** | Bottom dock with pinned apps, zoom-on-hover, auto-hide. Firefox, Files, Terminal, LibreOffice, GIMP, VLC, Settings, App Store |
| **Window buttons** | Close / minimize / maximize on the **left** (macOS-style) |
| **Compositor** | Picom: drop shadows, rounded corners, fade animations, per-window transparency |
| **Theme** | WhiteSur-Dark (GTK + icons + cursors), Fira Code for terminal |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Super` | Open App Menu |
| `Super+Space` | App Finder (Spotlight-like) |
| `Ctrl+Alt+T` | Terminal |
| `Super+E` | File Manager |
| `Super+B` | Browser |
| `Super+I` | Settings |
| `Super+L` | Lock Screen |
| `Super+D` | Show Desktop |
| `Super+Left/Right` | Tile window |
| `Super+Up` | Maximize |
| `Super+F` | Fullscreen |
| `Super+C` | Calculator |
| `Super+V` | Clipboard history |
| `Alt+Tab` | Switch windows |
| `Print` | Screenshot (Flameshot) |

## Installing Software

### App Store

Click the **App Store** icon in the dock (GNOME Software). Browse and install apps from Flatpak/Flathub with one click.

### Terminal

```bash
cursoros-install vlc             # Install a package
cursoros-install --search video  # Search
cursoros-install --popular       # List popular packages
sudo apt install <anything>     # Full Debian repos
```

### Ollama AI

```bash
install-ollama                   # Install Ollama
install-ollama --with-model      # Install + download starter model

ollama pull llama3.2             # Llama 3.2 (2GB)
ollama pull codellama            # Code Llama (3.8GB)
ollama pull deepseek-r1:8b       # DeepSeek R1 (4.7GB)
ollama run llama3.2              # Start chatting
```

## Pre-installed Software

| Category | Software |
|----------|----------|
| **Desktop** | XFCE4 + Plank Dock + Picom compositor |
| **Browser** | Firefox ESR |
| **Office** | LibreOffice (Writer, Calc, Impress, Draw, Math) |
| **Graphics** | GIMP, Inkscape, Shotwell, Ristretto, Drawing |
| **Media** | VLC, Parole, Celluloid, Cheese (webcam), ffmpeg |
| **System** | htop, btop, neofetch, GParted, GNOME Disks, Baobab |
| **Utilities** | GNOME Calculator, Calendar, Clocks, Evince (PDF), Flameshot, Simple Scan |
| **Development** | Python 3, Node.js, GCC, CMake, Git |
| **Networking** | NetworkManager, Bluetooth, OpenVPN |
| **Printing** | CUPS + all major printer drivers |
| **Security** | GNOME Keyring, Seahorse |
| **Backup** | Timeshift |
| **App Store** | GNOME Software + Flatpak (Flathub) |
| **AI** | Ollama (via installer) |

## Building

### Requirements

- Debian 12+ or Ubuntu 22.04+ host
- ~15 GB free disk space
- Root access (sudo)
- Internet connection
- Build time: **30-60 minutes**

```bash
# The build script handles its own dependencies, but you can pre-install:
sudo apt install debootstrap squashfs-tools xorriso grub-pc-bin \
    grub-efi-amd64-bin mtools git
```

### Build

```bash
cd os
sudo ./build.sh
```

### Options

```bash
sudo ./build.sh                # Full build with WhiteSur themes
sudo ./build.sh --skip-themes  # Skip WhiteSur download (uses Papirus/Arc)
sudo ./build.sh --clean        # Remove all build artifacts
```

## Running

### QEMU (recommended for testing)

```bash
qemu-system-x86_64 \
    -cdrom CursorOS-3.0.0-amd64.iso \
    -m 4G \
    -enable-kvm \
    -smp 2 \
    -vga virtio
```

### VirtualBox

1. New VM → Type: Linux, Version: Debian (64-bit)
2. RAM: 4096 MB, Processors: 2
3. Skip hard disk
4. Settings → Storage → Add optical drive → select ISO
5. Settings → Display → Video Memory: 128 MB, enable 3D acceleration
6. Start

### Real Hardware

```bash
# CAREFUL - replace /dev/sdX with your actual USB device!
lsblk   # Find your USB
sudo dd if=CursorOS-3.0.0-amd64.iso of=/dev/sdX bs=4M status=progress
sync
```

Boot from USB in BIOS/UEFI. Supports both Legacy and UEFI boot.

## System Requirements

| | Minimum | Recommended |
|--|---------|-------------|
| RAM | 2 GB | 4+ GB |
| CPU | 1 core x86_64 | 2+ cores |
| Disk | Live mode (0 GB) | 20+ GB for persistence |
| GPU | Any | VESA/Intel/AMD/NVIDIA |

For Ollama: 4+ GB RAM, 8+ GB recommended for larger models.

## Project Structure

```
os/
├── build.sh                         # 10-phase ISO build script
├── Makefile                         # make iso / make bare-metal
│
├── includes/                        # Overlay files → rootfs
│   └── etc/skel/                    # User home template
│       ├── .bashrc                  # Premium shell config
│       └── .config/
│           ├── xfce4/               # Desktop, panel, WM, terminal
│           ├── picom/picom.conf     # Compositor effects
│           ├── plank/dock1/         # Dock layout + pinned apps
│           ├── autostart/           # Plank, picom, nm, bluetooth, etc.
│           └── redshift/            # Night light config
│
├── scripts/                         # Custom CursorOS commands
│   ├── install-ollama.sh            # → /usr/local/bin/install-ollama
│   ├── cursoros-help.sh             # → /usr/local/bin/cursoros-help
│   ├── cursoros-install.sh          # → /usr/local/bin/cursoros-install
│   └── cursoros-about.sh            # → /usr/local/bin/cursoros-about
│
└── bare-metal/                      # Educational x86 kernel (bonus)
    ├── boot/ kernel/ drivers/ lib/
    ├── linker.ld
    └── Makefile
```

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│  Applications                                              │
│  Firefox ─ LibreOffice ─ GIMP ─ VLC ─ Ollama ─ Flatpaks  │
├────────────────────────────────────────────────────────────┤
│  Desktop Environment                                       │
│  XFCE4 ─ Plank Dock ─ Whisker Menu ─ Thunar              │
├────────────────────────────────────────────────────────────┤
│  Visual Layer                                              │
│  Picom (shadows/corners/fade) ─ WhiteSur Theme ─ X.Org   │
├────────────────────────────────────────────────────────────┤
│  System Services                                           │
│  NetworkManager ─ PulseAudio ─ CUPS ─ Bluetooth ─ systemd │
├────────────────────────────────────────────────────────────┤
│  Linux Kernel (Debian 12 Bookworm)                         │
│  TCP/IP ─ WiFi ─ USB ─ GPU ─ FS ─ Security               │
├────────────────────────────────────────────────────────────┤
│  GRUB2 + Plymouth Boot Splash                              │
└────────────────────────────────────────────────────────────┘
```

## License

MIT License — free to use, modify, and distribute.

## Credits

Built entirely with [Cursor AI](https://cursor.sh).
