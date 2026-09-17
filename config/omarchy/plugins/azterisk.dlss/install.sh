#!/usr/bin/env bash
# Complete All-In-One Installer for Omarchy DLSS 5 (azterisk.dlss)
# Author: Azteriisk

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="azterisk.dlss"
PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"
TARGET_DIR="$PLUGINS_DIR/$PLUGIN_ID"
BIN_DIR="$HOME/.local/bin"
CLI_TARGET="$BIN_DIR/omarchy-dlss"
APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/dlss"
CONFIG_FILE="$CONFIG_DIR/config.json"
SHELL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"

echo "󱚤 Installing Omarchy DLSS 5 plugin ($PLUGIN_ID)..."

# 1. Ensure target directories exist
mkdir -p "$PLUGINS_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$APPS_DIR"
mkdir -p "$CONFIG_DIR"

# 2. If running outside plugins dir, copy plugin files
if [ "$SCRIPT_DIR" != "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
  cp -a "$SCRIPT_DIR/manifest.json" \
        "$SCRIPT_DIR/Service.qml" \
        "$SCRIPT_DIR/BarWidget.qml" \
        "$SCRIPT_DIR/config.default.json" \
        "$SCRIPT_DIR/omarchy-dlss.desktop" \
        "$SCRIPT_DIR/scripts" \
        "$SCRIPT_DIR/assets" \
        "$SCRIPT_DIR/install.sh" \
        "$SCRIPT_DIR/uninstall.sh" \
        "$SCRIPT_DIR/README.md" "$TARGET_DIR/"
fi

# 2b. Ensure neural rendering binaries exist in assets/bin
if [ ! -f "$TARGET_DIR/assets/bin/nvngx_dlssnr.dll" ]; then
  echo "  📥 Downloading prepackaged DLSS 5 Neural Rendering binaries..."
  mkdir -p "$TARGET_DIR/assets/bin"
  ASSET_URL="https://github.com/Azteriisk/omarchy-dlss/releases/latest/download/omarchy-dlss-assets.tar.gz"
  if curl -f -sSL -o /tmp/omarchy-dlss-assets.tar.gz "$ASSET_URL"; then
    tar -xzf /tmp/omarchy-dlss-assets.tar.gz -C "$TARGET_DIR/assets"
    rm -f /tmp/omarchy-dlss-assets.tar.gz
    echo "  ✓ Binaries unpacked successfully"
  else
    echo "  ⚠ Warning: Could not automatically download release binaries."
    echo "    Please place nvngx_dlssnr.dll and OptiScaler in $TARGET_DIR/assets/bin/"
  fi
fi

# 3. Ensure scripts are executable & symlink CLI
chmod +x "$TARGET_DIR/scripts/omarchy-dlss"
chmod +x "$TARGET_DIR/scripts/omarchy-dlss-gui"
chmod +x "$TARGET_DIR/scripts/omarchy-dlss-menu"
ln -sf "$TARGET_DIR/scripts/omarchy-dlss" "$CLI_TARGET"
ln -sf "$TARGET_DIR/scripts/omarchy-dlss-gui" "$BIN_DIR/omarchy-dlss-gui"
echo "  ✓ Symlinked omarchy-dlss to $CLI_TARGET"
echo "  ✓ Symlinked omarchy-dlss-gui to $BIN_DIR/omarchy-dlss-gui"

# 4. Install desktop entry
cp "$TARGET_DIR/omarchy-dlss.desktop" "$APPS_DIR/omarchy-dlss.desktop"
update-desktop-database "$APPS_DIR" 2>/dev/null || true
echo "  ✓ Installed desktop application entry"

# 5. Initialize config file if not present
if [[ ! -f "$CONFIG_FILE" ]]; then
  cp "$TARGET_DIR/config.default.json" "$CONFIG_FILE"
  echo "  ✓ Created default DLSS configuration at $CONFIG_FILE"
fi

# 6. Configure shell.json to register azterisk.dlss in plugins[]
if [[ -f "$SHELL_CONFIG" ]]; then
  echo "  ⚙ Configuring shell.json for azterisk.dlss service..."
  python3 - << 'PYEOF'
import json
from pathlib import Path

shell_file = Path.home() / ".config" / "omarchy" / "shell.json"
try:
    with open(shell_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    if "plugins" not in data or not isinstance(data["plugins"], list):
        data["plugins"] = []

    has_plugin = any(isinstance(p, dict) and p.get("id") == "azterisk.dlss" for p in data["plugins"])
    if not has_plugin:
        data["plugins"].append({"id": "azterisk.dlss"})

    with open(shell_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    print("     [OK] shell.json updated successfully")
except Exception as err:
    print(f"     [WARN] Could not update shell.json: {err}")
PYEOF
fi

# 7. Reload Omarchy shell
if command -v omarchy >/dev/null 2>&1; then
  echo "  ✓ Reloading Omarchy shell..."
  omarchy restart shell 2>/dev/null || true
elif command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins 2>/dev/null || true
fi

echo ""
echo "======================================================================"
echo "  󱚤 Omarchy DLSS 5 installed successfully!"
echo "======================================================================"
echo "  Features:"
echo "    • GUI App: Launch 'Omarchy DLSS 5' from application menu or run 'omarchy-dlss gui'"
echo "    • CLI Utility: run 'omarchy-dlss list' or 'omarchy-dlss enable <game>'"
echo "    • Interactive Menu: run 'omarchy-dlss menu'"
echo "    • Optional top-bar widget available: 'azterisk.dlss'"
echo "======================================================================"
