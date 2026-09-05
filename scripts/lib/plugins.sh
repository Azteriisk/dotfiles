#!/usr/bin/env bash
# plugins.sh - Plugin management and automated installation for presets

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PRESETS_DIR="$DOTFILES_DIR/presets"

list_plugins() {
  local preset="${1:-$(get_active_preset)}"
  local pfile="$PRESETS_DIR/$preset/plugins.json"

  ui_header "Plugins for Preset: $preset"

  if [ ! -f "$pfile" ]; then
    ui_info "No plugins.json defined for preset '$preset'."
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json
plugins = json.load(open('$pfile'))
for p in plugins:
    print(f\"  \033[1;32m●\033[0m \033[1m{p.get('name', 'Unknown')}\033[0m ({p.get('id', '')})\")
    print(f\"    \033[2m{p.get('description', '')}\033[0m\")
    print(f\"    Repo: {p.get('repository', '')}\")
    print()
"
  else
    ui_info "Raw manifest: $pfile"
    cat "$pfile"
  fi
}

install_plugins() {
  local preset="${1:-$(get_active_preset)}"
  local pfile="$PRESETS_DIR/$preset/plugins.json"

  ui_header "Installing Plugins for Preset: $preset"

  if [ ! -f "$pfile" ]; then
    ui_info "No plugins.json found for preset '$preset'. Skipping plugin installation."
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    ui_warn "python3 is required to parse plugins manifest."
    return 1
  fi

  local count
  count="$(python3 -c "import json; print(len(json.load(open('$pfile'))))" 2>/dev/null || echo "0")"

  if [ "$count" -eq 0 ]; then
    ui_info "No plugins registered in $pfile."
    return 0
  fi

  ui_info "Found $count plugin(s) to install."

  # Process each plugin
  local idx=0
  while [ "$idx" -lt "$count" ]; do
    local pname pid ptype pinstall prep
    pname="$(python3 -c "import json; print(json.load(open('$pfile'))[$idx].get('name', ''))")"
    pid="$(python3 -c "import json; print(json.load(open('$pfile'))[$idx].get('id', ''))")"
    ptype="$(python3 -c "import json; print(json.load(open('$pfile'))[$idx].get('type', ''))")"
    prep="$(python3 -c "import json; print(json.load(open('$pfile'))[$idx].get('repository', ''))")"
    pinstall="$(python3 -c "import json; print(json.load(open('$pfile'))[$idx].get('install', ''))")"

    ui_section "Installing: $pname ($pid)"

    # Native Omarchy CLI check
    if [ "$ptype" = "omarchy-cli" ] && command -v omarchy >/dev/null 2>&1; then
      ui_step "Running native installer: $pinstall"
      eval "$pinstall" || ui_warn "Native installer exited with non-zero status."
    elif [ -n "$pinstall" ]; then
      ui_step "Running install command..."
      eval "$pinstall" || ui_warn "Plugin install command reported an error."
    else
      # Direct git clone fallback
      local target_dest="$HOME/.config/omarchy/plugins/$pid"
      if [ -d "$target_dest" ]; then
        ui_info "Plugin directory already exists at $target_dest"
      elif [ -n "$prep" ]; then
        ui_step "Cloning $prep -> $target_dest"
        mkdir -p "$(dirname "$target_dest")"
        git clone "$prep" "$target_dest"
      fi
    fi

    idx=$((idx + 1))
  done

  ui_success "Plugin installation routine completed."
}
