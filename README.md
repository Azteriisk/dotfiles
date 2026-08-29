# Azteriisk Dotfiles

Private configuration backup and synchronization for Omarchy, Hyprland, and desktop utilities.

## Tracked Configurations

| Component | Path | Description |
|-----------|------|-------------|
| **Omarchy** | `~/.config/omarchy/` | Shell config (`shell.json`), cloned user plugins (`azterisk.idle`, `azterisk.indicators`, etc.), hooks, branding |
| **Hyprland** | `~/.config/hypr/` | Window rules, monitor configs, keybindings, look and feel |
| **Terminals** | `~/.config/{ghostty,alacritty,kitty,foot}/` | Terminal styling and configurations |
| **Btop** | `~/.config/btop/` | System resource monitor config |
| **Starship** | `~/.config/starship.toml` | Cross-shell prompt configuration |

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
