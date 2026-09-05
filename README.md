# Azteriisk Dotfiles

Private configuration backup and synchronization for Omarchy, Hyprland, and desktop utilities.

## Tracked Configurations

| Component | Path | Description |
|-----------|------|-------------|
| **Omarchy** | `~/.config/omarchy/` | Shell config (`shell.json`), cloned user plugins (`azterisk.idle`, `azterisk.indicators`, etc.), hooks, branding |
| **Hyprland** | `~/.config/hypr/` | Window rules, monitor configs, keybindings, look and feel |
| **Systemd User** | `~/.config/systemd/user/` | User services and drop-in overrides (`omarchy-crash-watch`, `voxtype`) |
| **Scripts** | `~/.local/bin/` | Custom CLI tools, agent wrappers, and utility scripts |
| **Terminals** | `~/.config/{ghostty,alacritty,kitty,foot}/` | Terminal styling and configurations |
| **Btop** | `~/.config/btop/` | System resource monitor config |
| **Starship** | `~/.config/starship.toml` | Cross-shell prompt configuration |

---

## Custom Omarchy Plugins

A suite of modular extensions designed specifically for Omarchy and Hyprland. Each project lives in `~/Projects` and is publicly hosted on GitHub.

| Plugin | ID | Description | Best Install Method |
| :--- | :--- | :--- | :--- |
| [**`omarchy-display-manager`**](https://github.com/Azteriisk/omarchy-display-manager) | `azterisk.display-manager` | Interactive visual drag-and-drop monitor layout, per-monitor rotation, center offsets, and workspace renumbering | **`omarchy plugin add`** (Native) |
| [**`omarchy-idle-manager`**](https://github.com/Azteriisk/omarchy-idle-manager) | `azterisk.idle` | Screensaver & lock idle management, independent timers, Stay Awake modes (*Screensaver-Only* vs *Inhibit-All*), and top-bar popover | **`omarchy plugin add`** (Native) |
| [**`omarchy-window-minimize`**](https://github.com/Azteriisk/omarchy-window-minimize) | `azterisk.minimize` | Hyprland C++ CSD interceptor hook, window hiding/restoring, top-bar drawer badge, and shortcut bindings | **One-Line Installer** (Automated build & bindings) |
| [**`omarchy-wallpaper-engine`**](https://github.com/Azteriisk/omarchy-wallpaper-engine) | `azterisk.wallpaper-engine` | Steam Wallpaper Engine integration for Scene, Video, and HTML5 Web wallpapers, theme sync hook, and audio reactivity | **One-Line Installer** (CLI links & theme hooks) |

### Recommended Installation Commands

#### 1. Display Manager (`omarchy-display-manager`)
> **Best Method: Native Omarchy CLI**  
> Pure QML & JavaScript with zero compilation or system hooks. Native installation handles cloning, validation, and bar placement immediately:
```bash
omarchy plugin add https://github.com/Azteriisk/omarchy-display-manager.git --enable --yes
```

#### 2. Idle & Screensaver Manager (`omarchy-idle-manager`)
> **Best Method: Native Omarchy CLI**  
> Unified headless idle detection service and top-bar Stay Awake widget. Native installation activates the service and adds the navbar popover:
```bash
omarchy plugin add https://github.com/Azteriisk/omarchy-idle-manager.git --enable --yes
```

#### 3. Window Minimize (`omarchy-window-minimize`)
> **Best Method: One-Line Git Installer**  
> Hybrid plugin requiring a compiled C++ Hyprland hook (`minimize-hook.so`), CLI helper in `~/.local/bin/omarchy-minimize`, autostart entries in `autostart.lua`, and keybindings in `bindings.lua`. The installer handles all steps automatically:
```bash
git clone https://github.com/Azteriisk/omarchy-window-minimize.git && cd omarchy-window-minimize && ./install.sh
```

#### 4. Wallpaper Engine (`omarchy-wallpaper-engine`)
> **Best Method: One-Line Git Installer**  
> Integrates with `linux-wallpaperengine`, links the `omarchy-wpe` helper into `~/.local/bin`, and registers the live theme change hook in `~/.config/omarchy/hooks/theme-set.d/wpe-theme-sync.sh`:
```bash
git clone https://github.com/Azteriisk/omarchy-wallpaper-engine.git && cd omarchy-wallpaper-engine && ./install.sh
```
*(Prerequisite: `yay -S linux-wallpaperengine-git`)*

---

## Quick Usage

### Backup & Sync Changes
To pull your active configs from `~/.config/`, commit, and push to GitHub in one command:
```bash
~/dotfiles/backup.sh "feat: update keybindings and idle service"
```
Or without arguments (uses an automated timestamp):
```bash
~/dotfiles/backup.sh
```

### Restore / Deploy to a Machine
To restore or apply these dotfiles to `~/.config/` (automatically backs up existing configs first):
```bash
~/dotfiles/install.sh
```
