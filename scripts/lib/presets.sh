#!/usr/bin/env bash
# presets.sh - Core preset management, switching, saving, and deployment

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PRESETS_DIR="$DOTFILES_DIR/presets"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
ACTIVE_FILE="$STATE_DIR/active-preset"
DEFAULT_PRESET="default"

# Read JSON string value using python3, jq, or grep fallback
json_get() {
  local json_file="$1"
  local key="$2"
  local default_val="${3:-}"

  if [ ! -f "$json_file" ]; then
    echo "$default_val"
    return
  fi

  if command -v jq >/dev/null 2>&1; then
    local res
    res="$(jq -r --arg k "$key" '.[$k] // empty' "$json_file" 2>/dev/null)"
    if [ -n "$res" ] && [ "$res" != "null" ]; then
      echo "$res"
      return
    fi
  elif command -v python3 >/dev/null 2>&1; then
    local res
    res="$(python3 -c "import json, sys; d = json.load(open('$json_file')); print(d.get('$key', ''))" 2>/dev/null)"
    if [ -n "$res" ]; then
      echo "$res"
      return
    fi
  fi

  # Fallback: simple grep
  local val
  val="$(grep -m1 "\"$key\"" "$json_file" 2>/dev/null | sed -E 's/.*"[^"]+":[[:space:]]*"?([^",]*)"?.*/\1/' | tr -d '\r')"
  if [ -n "$val" ]; then
    echo "$val"
  else
    echo "$default_val"
  fi
}

get_active_preset() {
  if [ -f "$ACTIVE_FILE" ]; then
    cat "$ACTIVE_FILE"
  else
    echo "$DEFAULT_PRESET"
  fi
}

set_active_preset() {
  local name="$1"
  mkdir -p "$STATE_DIR"
  echo "$name" > "$ACTIVE_FILE"
}

preset_exists() {
  local name="$1"
  [ -d "$PRESETS_DIR/$name" ] && [ -f "$PRESETS_DIR/$name/preset.json" ]
}

list_presets() {
  local active
  active="$(get_active_preset)"

  ui_header "Available Presets"
  echo ""

  if [ ! -d "$PRESETS_DIR" ]; then
    ui_warn "No presets directory found at $PRESETS_DIR"
    return
  fi

  for pdir in "$PRESETS_DIR"/*; do
    if [ -d "$pdir" ] && [ -f "$pdir/preset.json" ]; then
      local name
      name="$(basename "$pdir")"
      local title
      title="$(json_get "$pdir/preset.json" "title" "$name")"
      local desc
      desc="$(json_get "$pdir/preset.json" "description" "")"

      if [ "$name" = "$active" ]; then
        printf "  ${GREEN}${BOLD}* %-14s${RESET} ${BOLD}%-36s${RESET} ${GREEN}[ACTIVE]${RESET}\n" "$name" "$title"
      else
        printf "    %-14s %-36s\n" "$name" "$title"
      fi
      if [ -n "$desc" ]; then
        printf "      ${DIM}%s${RESET}\n" "$desc"
      fi
      echo ""
    fi
  done
}

preset_info() {
  local name="$1"
  local pdir="$PRESETS_DIR/$name"
  local manifest="$pdir/preset.json"

  if ! preset_exists "$name"; then
    ui_fatal "Preset '$name' not found."
  fi

  local title desc author version
  title="$(json_get "$manifest" "title" "$name")"
  desc="$(json_get "$manifest" "description" "No description")"
  author="$(json_get "$manifest" "author" "Unknown")"
  version="$(json_get "$manifest" "version" "1.0.0")"

  ui_header "Preset: $name"
  echo "  Title:       $title"
  echo "  Author:      $author"
  echo "  Version:     $version"
  echo "  Description: $desc"
  echo "  Path:        $pdir"
  echo ""

  if [ -d "$pdir/config" ]; then
    ui_section "Configurations (~/.config):"
    for item in "$pdir/config"/*; do
      [ -e "$item" ] || continue
      echo "   - $(basename "$item")"
    done
    echo ""
  fi

  if [ -d "$pdir/bin" ]; then
    ui_section "User Binaries (~/.local/bin):"
    for item in "$pdir/bin"/*; do
      [ -e "$item" ] || continue
      echo "   - $(basename "$item")"
    done
    echo ""
  fi

  if [ -f "$pdir/plugins.json" ]; then
    ui_section "Plugins Manifest:"
    echo "   $pdir/plugins.json"
    echo ""
  fi
}

# Create a safety backup before switching or installing
create_safety_backup() {
  local tag="${1:-pre-switch}"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local backup_path="$HOME/.config/dotfiles-backups/$timestamp-$tag"

  mkdir -p "$backup_path"
  ui_info "Creating automatic safety snapshot at $backup_path..."

  # Backup tracked active items
  local active
  active="$(get_active_preset)"
  local manifest="$PRESETS_DIR/$active/preset.json"

  if [ -d "$HOME/.config" ]; then
    mkdir -p "$backup_path/config"
    if [ -f "$manifest" ]; then
      # Read tracked dirs if possible
      local dirs
      dirs="$(python3 -c "import json; [print(x) for x in json.load(open('$manifest')).get('tracked', {}).get('config_dirs', [])]" 2>/dev/null || true)"
      for d in $dirs; do
        if [ -e "$HOME/.config/$d" ]; then
          cp -a "$HOME/.config/$d" "$backup_path/config/" 2>/dev/null || true
        fi
      done
      local files
      files="$(python3 -c "import json; [print(x) for x in json.load(open('$manifest')).get('tracked', {}).get('config_files', [])]" 2>/dev/null || true)"
      for f in $files; do
        if [ -e "$HOME/.config/$f" ]; then
          cp -a "$HOME/.config/$f" "$backup_path/config/" 2>/dev/null || true
        fi
      done
    fi
  fi

  ui_success "Safety snapshot saved."
  echo "$backup_path"
}

# Run hooks defined in preset.json
run_preset_hooks() {
  local name="$1"
  local manifest="$PRESETS_DIR/$name/preset.json"
  [ -f "$manifest" ] || return 0

  if command -v python3 >/dev/null 2>&1; then
    local hooks
    hooks="$(python3 -c "import json; [print(h) for h in json.load(open('$manifest')).get('hooks', {}).get('post_apply', [])]" 2>/dev/null || true)"
    if [ -n "$hooks" ]; then
      ui_section "Executing post-apply hooks for $name..."
      while IFS= read -r cmd; do
        [ -z "$cmd" ] && continue
        ui_step "Running: $cmd"
        eval "$cmd" || ui_warn "Hook non-zero exit: $cmd"
      done <<< "$hooks"
    fi
  fi
}

# Deploy preset (mode: symlink or copy)
deploy_preset() {
  local name="$1"
  local mode="${2:-symlink}"
  local dry_run="${3:-false}"
  local pdir="$PRESETS_DIR/$name"

  if ! preset_exists "$name"; then
    ui_fatal "Preset '$name' does not exist."
  fi

  ui_header "Deploying Preset: $name (Mode: $mode)"

  local conf_src="$pdir/config"
  local bin_src="$pdir/bin"

  mkdir -p "$HOME/.config" "$HOME/.local/bin"

  # Deploy configs
  if [ -d "$conf_src" ]; then
    for item in "$conf_src"/*; do
      [ -e "$item" ] || continue
      local base
      base="$(basename "$item")"
      local dest="$HOME/.config/$base"

      if [ "$dry_run" = "true" ]; then
        ui_step "[DRY-RUN] Deploy $item -> $dest"
        continue
      fi

      # If existing target is a symlink or file/dir, replace cleanly
      if [ -L "$dest" ] || [ -e "$dest" ]; then
        rm -rf "$dest"
      fi

      if [ "$mode" = "symlink" ]; then
        ln -sf "$item" "$dest"
        ui_step "Linked ~/.config/$base -> $item"
      else
        cp -a "$item" "$dest"
        ui_step "Copied $item -> ~/.config/$base"
      fi
    done
  fi

  # Deploy user binaries/scripts
  if [ -d "$bin_src" ]; then
    for item in "$bin_src"/*; do
      [ -e "$item" ] || continue
      local base
      base="$(basename "$item")"
      local dest="$HOME/.local/bin/$base"

      if [ "$dry_run" = "true" ]; then
        ui_step "[DRY-RUN] Deploy $item -> $dest"
        continue
      fi

      if [ -L "$dest" ] || [ -e "$dest" ]; then
        rm -rf "$dest"
      fi

      if [ "$mode" = "symlink" ]; then
        ln -sf "$item" "$dest"
        ui_step "Linked ~/.local/bin/$base -> $item"
      else
        cp -a "$item" "$dest"
        ui_step "Copied $item -> ~/.local/bin/$base"
      fi
    done
  fi

  if [ "$dry_run" = "false" ]; then
    set_active_preset "$name"
    run_preset_hooks "$name"
    ui_success "Preset '$name' is now active!"
  else
    ui_info "Dry-run complete. No changes were made."
  fi
}

# Switch to another preset instantly
switch_preset() {
  local name="$1"
  local mode="${2:-symlink}"

  if ! preset_exists "$name"; then
    ui_fatal "Preset '$name' not found in $PRESETS_DIR."
  fi

  local current
  current="$(get_active_preset)"
  if [ "$name" = "$current" ]; then
    ui_info "Preset '$name' is already active."
  fi

  create_safety_backup "pre-switch-to-$name" >/dev/null
  deploy_preset "$name" "$mode" "false"
}

# Save current machine setup into a preset
save_preset() {
  local name="$1"
  local title="${2:-$name Configuration}"
  local desc="${3:-Custom preset saved on $(date '+%Y-%m-%d %H:%M:%S')}"
  local pdir="$PRESETS_DIR/$name"

  ui_header "Saving Current Setup into Preset: $name"

  mkdir -p "$pdir/config" "$pdir/bin"

  # Base target configs (Omarchy, Hypr, Terminals, Starship, Btop, etc.)
  local default_targets=(
    "omarchy"
    "hypr"
    "ghostty"
    "alacritty"
    "kitty"
    "foot"
    "btop"
    "systemd/user"
  )

  local tracked_dirs=()
  for t in "${default_targets[@]}"; do
    if [ -d "$HOME/.config/$t" ]; then
      ui_step "Syncing ~/.config/$t"
      mkdir -p "$pdir/config/$t"
      rsync -a --delete \
        --exclude='.git/' \
        --exclude='*.log' \
        --exclude='*.pid' \
        --exclude='*.sock' \
        --exclude='*.lock' \
        --exclude='*.tmp' \
        --exclude='*.bak*' \
        "$HOME/.config/$t/" "$pdir/config/$t/"
      tracked_dirs+=("$t")
    fi
  done

  local tracked_files=()
  if [ -f "$HOME/.config/starship.toml" ]; then
    ui_step "Syncing ~/.config/starship.toml"
    cp -f "$HOME/.config/starship.toml" "$pdir/config/starship.toml"
    tracked_files+=("starship.toml")
  fi

  if [ -d "$HOME/.local/bin" ]; then
    ui_step "Syncing ~/.local/bin"
    rsync -a --delete \
      --exclude='.git/' \
      "$HOME/.local/bin/" "$pdir/bin/"
  fi

  # Generate preset.json
  local manifest="$pdir/preset.json"
  cat << PRESET_EOF > "$manifest"
{
  "name": "$name",
  "title": "$title",
  "description": "$desc",
  "author": "${USER:-$LOGNAME}",
  "version": "1.0.0",
  "hooks": {
    "post_apply": [
      "if command -v systemctl >/dev/null 2>&1; then systemctl --user daemon-reload || true; fi",
      "if command -v omarchy-shell >/dev/null 2>&1; then omarchy-shell shell reloadConfig 2>/dev/null || true; fi",
      "if command -v hyprctl >/dev/null 2>&1; then hyprctl reload 2>/dev/null || true; fi"
    ]
  },
  "tracked": {
    "config_dirs": [$(printf '"%s",' "${tracked_dirs[@]}" | sed 's/,$//')],
    "config_files": [$(printf '"%s",' "${tracked_files[@]}" | sed 's/,$//')],
    "bin": true
  }
}
PRESET_EOF

  ui_success "Preset '$name' successfully created and saved!"
  ui_info "Location: $pdir"
}

# Clone preset
clone_preset() {
  local src="$1"
  local dst="$2"

  if ! preset_exists "$src"; then
    ui_fatal "Source preset '$src' does not exist."
  fi

  if preset_exists "$dst"; then
    ui_fatal "Target preset '$dst' already exists."
  fi

  ui_header "Cloning Preset '$src' to '$dst'..."
  cp -a "$PRESETS_DIR/$src" "$PRESETS_DIR/$dst"

  # Update name in preset.json
  local manifest="$PRESETS_DIR/$dst/preset.json"
  if [ -f "$manifest" ] && command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json
d = json.load(open('$manifest'))
d['name'] = '$dst'
d['title'] = '$dst (Cloned from $src)'
json.dump(d, open('$manifest', 'w'), indent=2)
"
  fi

  ui_success "Preset cloned to '$dst'."
}

# Delete preset
delete_preset() {
  local name="$1"

  if ! preset_exists "$name"; then
    ui_fatal "Preset '$name' does not exist."
  fi

  local active
  active="$(get_active_preset)"
  if [ "$name" = "$active" ]; then
    ui_fatal "Cannot delete currently active preset '$name'. Switch to another preset first."
  fi

  if ui_confirm "Are you sure you want to permanently delete preset '$name'?" "N"; then
    rm -rf "$PRESETS_DIR/$name"
    ui_success "Preset '$name' deleted."
  else
    ui_info "Deletion cancelled."
  fi
}
