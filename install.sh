#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$DOTFILES_DIR/config"
BACKUP_DIR="$HOME/.config/backup-$(date +%Y%m%d-%H%M%S)"

echo "==> Installing dotfiles to ~/.config..."

TARGET_DIRS=(
  "omarchy"
  "hypr"
  "ghostty"
  "alacritty"
  "kitty"
  "foot"
  "btop"
  "systemd/user"
)

TARGET_FILES=(
  "starship.toml"
)

# Create backup of current configs
echo "==> Creating backup of existing configs at $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"

for dir in "${TARGET_DIRS[@]}"; do
  if [ -d "$HOME/.config/$dir" ]; then
    cp -r "$HOME/.config/$dir" "$BACKUP_DIR/"
  fi
done

for file in "${TARGET_FILES[@]}"; do
  if [ -f "$HOME/.config/$file" ]; then
    cp "$HOME/.config/$file" "$BACKUP_DIR/"
  fi
done

echo "==> Deploying configurations..."

for dir in "${TARGET_DIRS[@]}"; do
  if [ -d "$CONFIG_DIR/$dir" ]; then
    echo " -> Restoring ~/.config/$dir"
    mkdir -p "$HOME/.config/$dir"
    rsync -a "$CONFIG_DIR/$dir/" "$HOME/.config/$dir/"
  fi
done

for file in "${TARGET_FILES[@]}"; do
  if [ -f "$CONFIG_DIR/$file" ]; then
    echo " -> Restoring ~/.config/$file"
    cp -f "$CONFIG_DIR/$file" "$HOME/.config/$file"
  fi
done

# Deploy local user binaries / scripts
if [ -d "$DOTFILES_DIR/bin" ]; then
  echo " -> Restoring ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  rsync -a "$DOTFILES_DIR/bin/" "$HOME/.local/bin/"
fi

echo "==> Refreshing active session..."
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload 2>/dev/null || true
fi
if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell reloadConfig 2>/dev/null || true
  omarchy-shell shell rescanPlugins 2>/dev/null || true
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload 2>/dev/null || true
fi

echo "==> Dotfiles installation and reload complete!"
