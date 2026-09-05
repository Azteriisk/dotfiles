# Azteriisk Dotfiles & Preset Management System

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?logo=arch-linux&logoColor=white)](https://archlinux.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-00aaee)](https://hyprland.org)
[![Omarchy](https://img.shields.io/badge/Omarchy-Desktop-black)](https://github.com/Azteriisk)

A modular dotfiles management framework and personal desktop configuration for **Omarchy** and **Hyprland**. 

This repository serves two purposes:
1. **The Default Setup**: A complete, polished, daily-driver desktop environment built around Hyprland, custom Omarchy plugins, Wayland utilities, terminal configurations, and developer workflows.
2. **The Preset Engine (`dots`)**: A lightweight, multi-preset management system that allows you to snapshot your configs and plugins, clone your setup onto new machines with a single command, and swap between completely different desktop profiles instantly.

---

## 🚀 Quickstart: Deploy on Any Machine

To clone and install this setup on a fresh machine:

```bash
git clone https://github.com/Azteriisk/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The installer will:
- Safely create a timestamped backup of existing configurations in `~/.config/dotfiles-backups/`.
- Let you choose between presets (e.g. `default` for the full desktop or `minimal` for terminal-only).
- Symlink configs and helper binaries cleanly into place.
- Prompt to automatically clone and build the included custom Omarchy plugins.

---

## ⚡ The `dots` CLI: Instant Preset Swapping

The repository includes a standalone, zero-dependency CLI tool called `dots` that handles preset switching, live syncing, and system health audits.

```text
       __      __  _____ __          
  ____/ /___  / /_/ __(_) /__  _____ 
 / __  / __ \/ __/ /_/ / / _ \/ ___/ 
/ /_/ / /_/ / /_/ __/ / /  __(__  )  
\__,_/\____/\__/_/ /_/_/\___/____/   
  Multi-Preset System & Sync Framework
```

### 1. Swapping Presets Instantly
Switch between completely different desktop configurations with a single command:

```bash
# Switch to the full Omarchy + Hyprland desktop
./dots preset switch default

# Switch instantly to a lightweight terminal & CLI environment
./dots preset switch minimal
```
*When switching, `dots` swaps configuration symlinks and automatically triggers reload hooks (`hyprctl reload`, `omarchy-shell reloadConfig`, `systemctl --user daemon-reload`).*

### 2. Saving Your Active Setup as a New Preset
Tweak your desktop, install new tools, and snapshot the result into a reusable preset:

```bash
# Save your current configuration state as 'work-station'
./dots preset save work-station "Workstation Setup" "Dual-monitor layout with productivity tools"

# Fork an existing preset to iterate safely
./dots preset clone default gaming-setup
```

### 3. Backing Up & Git Syncing
Sync your active configurations from `~/.config/` into the active preset with automatic secret scanning:

```bash
# Backup and commit with custom message
./dots backup -m "feat: adjust ghostty padding and hyprland master layout"

# Backup, commit, and push directly to GitHub
./dots backup --push -m "feat: sync updated starship prompt"
```

### 4. Inspecting Status & Running Security Audits
```bash
# View active preset, git status, and drift
./dots status

# Run security scan, broken symlink check, and portability audit
./dots doctor
```

---

## 🎛 Included Presets

| Preset | Description | Targets |
| :--- | :--- | :--- |
| **`default`** *(Active)* | **Azteriisk Personal Desktop**: Full Omarchy shell, custom plugins, Hyprland window rules, terminal styling, user systemd units, and developer tool wrappers. | `omarchy`, `hypr`, `ghostty`, `alacritty`, `kitty`, `foot`, `btop`, `systemd/user`, `starship.toml`, `~/.local/bin/` |
| **`minimal`** | **Lightweight Terminal Environment**: Clean configuration stripped down to terminal emulators, system monitor, and prompt. Ideal for servers, VMs, or distraction-free coding. | `ghostty`, `btop`, `starship.toml` |

---

## 🖥 The Default Setup: Tracked Configurations

The `default` preset tracks and orchestrates the following components:

| Component | Target Path | Description |
| :--- | :--- | :--- |
| **Omarchy** | `~/.config/omarchy/` | Shell layout (`shell.json`), custom plugins, hooks (`theme-set.d`, `post-boot.d`), branding, backgrounds |
| **Hyprland** | `~/.config/hypr/` | Window rules, monitor setups (`monitors.lua`), keybindings (`bindings.lua`), look and feel |
| **Systemd User** | `~/.config/systemd/user/` | Background user services and overrides (`omarchy-crash-watch`, `voxtype`) |
| **Scripts & CLI** | `~/.local/bin/` | Custom binaries, desktop helpers (`omarchy-minimize`, `omarchy-wpe`), and agent wrappers |
| **Terminals** | `~/.config/{ghostty,alacritty,kitty,foot}/` | Comprehensive styling, font rendering, and terminal bindings |
| **Btop** | `~/.config/btop/` | System resource monitor with theme synchronization |
| **Starship** | `~/.config/starship.toml` | High-performance cross-shell prompt configuration |

---

## 🧩 Custom Omarchy Plugins

A suite of modular extensions designed specifically for Omarchy and Hyprland. Each plugin is maintained as a dedicated open-source repository and can be installed natively or via the `dots plugins install` command:

| Plugin | ID | Description | Installation Method |
| :--- | :--- | :--- | :--- |
| [**`omarchy-display-manager`**](https://github.com/Azteriisk/omarchy-display-manager) | `azterisk.display-manager` | Interactive visual drag-and-drop monitor layout, per-monitor rotation, center offsets, and workspace renumbering. | **`omarchy plugin add`** (Native) |
| [**`omarchy-idle-manager`**](https://github.com/Azteriisk/omarchy-idle-manager) | `azterisk.idle` | Screensaver & lock idle management, independent timers, Stay Awake modes (*Screensaver-Only* vs *Inhibit-All*), and top-bar popover. | **`omarchy plugin add`** (Native) |
| [**`omarchy-games`**](https://github.com/Azteriisk/omarchy-games) | `azterisk.games` | Unified game library manager & launcher for Steam, Lutris, and RetroArch with dynamic game artwork and search bar indexing. | **`omarchy plugin add`** (Native) |
| [**`omarchy-window-minimize`**](https://github.com/Azteriisk/omarchy-window-minimize) | `azterisk.minimize` | Hyprland C++ CSD interceptor hook, window hiding/restoring, top-bar drawer badge, and shortcut bindings. | **One-Line Installer** (Automated build & bindings) |
| [**`omarchy-wallpaper-engine`**](https://github.com/Azteriisk/omarchy-wallpaper-engine) | `azterisk.wallpaper-engine` | Steam Wallpaper Engine integration for Scene, Video, and HTML5 Web wallpapers, theme sync hook, and audio reactivity. | **One-Line Installer** (CLI links & theme hooks) |

### Installing All Plugins Automatically
To install all plugins associated with the active preset:
```bash
./dots plugins install default
```

### Manual Plugin Installation Commands

#### 1. Display Manager (`omarchy-display-manager`)
```bash
omarchy plugin add https://github.com/Azteriisk/omarchy-display-manager.git --enable --yes
```

#### 2. Idle & Screensaver Manager (`omarchy-idle-manager`)
```bash
omarchy plugin add https://github.com/Azteriisk/omarchy-idle-manager.git --enable --yes
```

#### 3. Games Library & Launcher (`omarchy-games`)
```bash
omarchy plugin add https://github.com/Azteriisk/omarchy-games.git --enable --yes
```

#### 4. Window Minimize (`omarchy-window-minimize`)
```bash
git clone https://github.com/Azteriisk/omarchy-window-minimize.git /tmp/omarchy-window-minimize \
  && cd /tmp/omarchy-window-minimize && ./install.sh && rm -rf /tmp/omarchy-window-minimize
```

#### 5. Wallpaper Engine (`omarchy-wallpaper-engine`)
```bash
git clone https://github.com/Azteriisk/omarchy-wallpaper-engine.git /tmp/omarchy-wallpaper-engine \
  && cd /tmp/omarchy-wallpaper-engine && ./install.sh && rm -rf /tmp/omarchy-wallpaper-engine
```
*(Prerequisite: `yay -S linux-wallpaperengine-git`)*

---

## 🛠 Command Reference

| Command | Description |
| :--- | :--- |
| **`./dots preset list`** | List all presets, descriptions, and mark the active preset. |
| **`./dots preset switch <name>`** | Instantly apply a preset, link configs, and reload desktop hooks. |
| **`./dots preset save <name>`** | Snapshot active system configs into a new or existing preset. |
| **`./dots preset clone <src> <dst>`** | Clone an existing preset to iterate on a new variation. |
| **`./dots preset info <name>`** | Display detailed preset metadata, tracked files, and hooks. |
| **`./dots preset delete <name>`** | Safely delete a non-active preset. |
| **`./dots install [--preset <name>]`** | Bootstrap on a new machine with automatic safety backups. |
| **`./dots backup [preset] [-m msg]`** | Sync system changes, scan for accidental secrets, and commit. |
| **`./dots status`** | Display active preset, tracked files count, and git status. |
| **`./dots doctor`** | Audit system health, verify symlink resolution, and scan for secret leaks. |
| **`./dots plugins list [preset]`** | View registered plugins for a preset. |
| **`./dots plugins install [preset]`** | Install all plugins registered in the preset. |

---

## 🔒 Security & Privacy

This repository is configured for public hosting:
- Built-in pre-commit secret scanner in `./dots backup` and `./dots doctor` guards against accidental API token, private key (`id_rsa`, `.pem`), or `.env` leaks.
- All symlinks use portable relative paths rather than machine-locked user paths (`/home/...`).
- Sensitive caches, cookies, logs, and process IDs are strictly ignored via `.gitignore`.

---

## 📄 License

Distributed under the [MIT License](LICENSE). Free to fork, adapt, and use for your own dotfile setups.
