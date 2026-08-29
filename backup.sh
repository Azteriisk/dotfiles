#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$DOTFILES_DIR/config"

echo "==> Backing up active configurations into dotfiles repository..."

# Target directories under ~/.config
TARGET_DIRS=(
  "omarchy"
  "hypr"
  "ghostty"
  "alacritty"
  "kitty"
  "foot"
  "btop"
)

# Target single files under ~/.config
TARGET_FILES=(
  "starship.toml"
)

mkdir -p "$CONFIG_DIR"

for dir in "${TARGET_DIRS[@]}"; do
  if [ -d "$HOME/.config/$dir" ]; then
    echo " -> Syncing ~/.config/$dir"
    mkdir -p "$CONFIG_DIR/$dir"
    rsync -a --delete \
      --exclude='.git/' \
      --exclude='*.log' \
      --exclude='*.pid' \
      --exclude='*.sock' \
      --exclude='*.lock' \
      --exclude='*.tmp' \
      --exclude='*.bak*' \
      "$HOME/.config/$dir/" "$CONFIG_DIR/$dir/"
  fi
done

for file in "${TARGET_FILES[@]}"; do
  if [ -f "$HOME/.config/$file" ]; then
    echo " -> Syncing ~/.config/$file"
    cp -f "$HOME/.config/$file" "$CONFIG_DIR/$file"
  fi
done

echo "==> Backup sync completed successfully."

# Check if git tracking is active in dotfiles
if [ -d "$DOTFILES_DIR/.git" ]; then
  cd "$DOTFILES_DIR"
  if [ -n "$(git status --porcelain)" ]; then
    echo "==> Changes detected in dotfiles."
    git status --short
    
    commit_msg="${1:-"chore(sync): update dotfiles backup $(date '+%Y-%m-%d %H:%M:%S')"}"
    git add .
    git commit -m "$commit_msg"
    
    if git remote get-url origin >/dev/null 2>&1; then
      echo "==> Pushing changes to remote..."
      git push origin "$(git branch --show-current)"
      echo "==> Pushed to remote repository."
    fi
  else
    echo "==> No configuration changes detected since last commit."
  fi
fi
