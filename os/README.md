# CursorOS

A custom Linux distribution built entirely with Cursor AI. CursorOS is a full desktop operating system with a graphical UI, web browser, internet connectivity, and the ability to install software -- including AI tools like Ollama.

## Features

- **Windows-like Desktop** - XFCE4 with bottom taskbar, start menu, system tray, window snapping
- **Web Browser** - Firefox ESR pre-installed for full internet browsing
- **Internet Access** - NetworkManager with WiFi and Ethernet support out of the box
- **Software Installation** - Install anything via `apt`, `cursoros-install`, or `curl`
- **Ollama AI Support** - One-command installer for running local AI models (`install-ollama`)
- **Live Boot** - Runs directly from USB or CD without installing to disk
- **Dark Theme** - Modern dark UI with custom CursorOS branding
- **Pre-installed Tools** - Terminal, file manager, text editor, task manager, htop, neofetch, git, and more

## Screenshots

After booting, you'll see:
- A GRUB boot menu with CursorOS branding
- Auto-login to a dark-themed XFCE4 desktop
- Bottom taskbar with Applications menu (like Windows Start), window list, system tray, clock
- Desktop icons for Firefox, Terminal, and Files
- Network applet in the system tray for WiFi/Ethernet

## Quick Start

### Running the Pre-built ISO

```bash
# In QEMU (recommended for testing)
qemu-system-x86_64 -cdrom CursorOS-2.0.0-amd64.iso -m 2G -enable-kvm -smp 2

# In VirtualBox: Create VM > Settings > Storage > Add CursorOS ISO > Boot
```

### Default Login

- **Username:** `cursor`
- **Password:** `cursor`
- Auto-login is enabled (boots straight to desktop)
- User has passwordless sudo

## Building the ISO

### Prerequisites

A **Debian or Ubuntu** host system with:
- ~10 GB free disk space
- Root access (sudo)
- Internet connection

```bash
# The build script installs its own dependencies, but you can pre-install:
sudo apt install debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools
```

### Build

```bash
cd os
sudo ./build.sh
```

The build takes **20-40 minutes** depending on your internet speed. It will:
1. Bootstrap a minimal Debian 12 (Bookworm) system
2. Install XFCE4 desktop, Firefox, NetworkManager, and all utilities
3. Apply CursorOS branding (wallpaper, theme, login screen, MOTD)
4. Install custom scripts (Ollama installer, help, package manager)
5. Create a compressed squashfs filesystem
6. Generate a bootable ISO with GRUB2

Output: `CursorOS-2.0.0-amd64.iso`

### Clean

```bash
sudo ./build.sh --clean
```

## Using CursorOS

### Desktop

The desktop uses a **Windows-like layout**:

| Element | Description |
|---------|-------------|
| Bottom panel | Taskbar with app menu, window list, tray, clock |
| Applications menu | Click "Applications" (bottom-left) or press Super key |
| Window snapping | Drag to edges, or Super+Arrow keys |
| Right-click desktop | Desktop menu with options |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Super` (Win key) | Open Applications menu |
| `Ctrl+Alt+T` | Open Terminal |
| `Ctrl+Alt+Delete` | Task Manager |
| `Super+E` | File Manager |
| `Super+L` | Lock Screen |
| `Super+D` | Show Desktop |
| `Super+Left/Right` | Tile window left/right |
| `Super+Up/Down` | Maximize/Minimize |
| `Alt+Tab` | Switch windows |
| `Alt+F4` | Close window |
| `Alt+F2` | Run command |
| `Print Screen` | Screenshot |

### Installing Software

```bash
# The friendly way
cursoros-install firefox     # Install a package
cursoros-install --search video  # Search packages
cursoros-install --popular   # Show popular packages

# Or use apt directly
sudo apt install vlc
sudo apt install nodejs npm
sudo apt install docker.io
```

### Installing Ollama (AI)

CursorOS comes with a dedicated Ollama installer:

```bash
# Install Ollama
install-ollama

# Install Ollama + download a starter model
install-ollama --with-model

# After installation:
ollama pull llama3.2        # Download Llama 3.2 (2GB)
ollama pull phi3            # Download Phi-3 (2.3GB)
ollama pull codellama       # Download Code Llama (3.8GB)
ollama pull llama3.2:1b     # Tiny 1B model (700MB)
ollama run llama3.2         # Chat with a model
```

The Ollama API is available at `http://localhost:11434` for integration with other tools.

### Networking

- **WiFi:** Click the network icon in the system tray, or run `nmtui` in terminal
- **Ethernet:** Automatically configured via DHCP
- **Manual config:** `nmcli`, `nmtui`, or NetworkManager GUI applet

### Help

```bash
cursoros-help     # Quick reference card
cursoros-about    # About CursorOS
neofetch          # System info with ASCII art
```

## Writing to USB

```bash
# Find your USB device (BE CAREFUL - wrong device = data loss!)
lsblk

# Write the ISO (replace /dev/sdX with your actual USB device)
sudo dd if=CursorOS-2.0.0-amd64.iso of=/dev/sdX bs=4M status=progress
sync
```

Boot from USB in your BIOS/UEFI boot menu. Supports both Legacy BIOS and UEFI boot.

## Project Structure

```
os/
├── build.sh                    # Main ISO build script
├── Makefile                    # Build targets (iso, bare-metal, clean)
├── README.md                   # This file
│
├── includes/                   # Files overlaid onto the rootfs
│   ├── etc/
│   │   └── skel/               # Default user home directory template
│   │       ├── .config/
│   │       │   ├── xfce4/      # XFCE desktop configuration
│   │       │   │   ├── xfconf/ # Panel, desktop, WM, theme settings
│   │       │   │   └── panel/  # Whisker menu (Start menu) config
│   │       │   └── autostart/  # Apps that start with desktop
│   │       └── Desktop/        # Desktop shortcut icons
│   └── usr/
│       └── share/
│           └── applications/   # .desktop files for app menu
│
├── scripts/                    # Custom CursorOS commands
│   ├── install-ollama.sh       # Ollama AI installer
│   ├── cursoros-help.sh        # Help quick reference
│   ├── cursoros-install.sh     # Friendly package installer
│   └── cursoros-about.sh       # About CursorOS
│
└── bare-metal/                 # Original bare-metal x86 kernel
    ├── boot/                   # Assembly bootloader
    ├── kernel/                 # C kernel (shell, GDT, IDT, memory)
    ├── drivers/                # VGA, keyboard, timer drivers
    ├── lib/                    # String/memory utilities
    ├── include/                # Header files
    ├── linker.ld               # Kernel linker script
    └── Makefile                # Bare-metal build system
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│              CursorOS Desktop                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │ Firefox  │ │ Terminal │ │  Ollama / Apps   │ │
│  │ Browser  │ │  (xfce4) │ │  (installable)   │ │
│  └──────────┘ └──────────┘ └──────────────────┘ │
├─────────────────────────────────────────────────┤
│  XFCE4 Desktop Environment                      │
│  (Whisker Menu, Taskbar, Window Manager)         │
├─────────────────────────────────────────────────┤
│  X.Org Display Server                            │
│  LightDM (Display Manager, Auto-login)           │
├─────────────────────────────────────────────────┤
│  NetworkManager    PulseAudio    systemd         │
│  (WiFi/Ethernet)   (Audio)      (Services)       │
├─────────────────────────────────────────────────┤
│  Linux Kernel (Debian 12 Bookworm)               │
│  (TCP/IP, Drivers, Filesystems, Security)        │
├─────────────────────────────────────────────────┤
│  GRUB2 Bootloader                                │
│  (BIOS + UEFI support)                           │
└─────────────────────────────────────────────────┘
```

## System Requirements

| Minimum | Recommended |
|---------|-------------|
| 1 GB RAM | 2+ GB RAM |
| 1 CPU core | 2+ cores |
| 5 GB disk (live) | 20+ GB (with apps) |
| Any x86_64 CPU | Intel/AMD 64-bit |

For Ollama: 4+ GB RAM recommended, 8+ GB for larger models.

## Included Software

| Category | Software |
|----------|----------|
| Desktop | XFCE4, Thunar, Mousepad, Ristretto |
| Browser | Firefox ESR |
| Terminal | XFCE4 Terminal |
| Network | NetworkManager, WiFi support |
| System | htop, neofetch, GParted, GNOME Disks |
| Dev | git, build-essential, curl, wget |
| Archive | file-roller, p7zip |
| Audio | PulseAudio, pavucontrol |
| AI | Ollama (via installer) |
| Package Mgr | apt, Synaptic, cursoros-install |

## Bare-Metal Kernel

The original CursorOS bare-metal kernel is preserved in `os/bare-metal/`. It's a from-scratch x86 kernel written in assembly and C with its own VGA driver, keyboard handler, and shell. Build it with:

```bash
cd os/bare-metal
make
qemu-system-i386 -cdrom CursorOS.iso
```

## License

MIT License - free to use, modify, and distribute.

## Credits

Built entirely with [Cursor AI](https://cursor.sh).
