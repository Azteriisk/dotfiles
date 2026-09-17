#!/usr/bin/env bash
# Uninstaller for Omarchy DLSS 5 (azterisk.dlss)
# Author: Azteriisk

set -euo pipefail

PLUGIN_ID="azterisk.dlss"
PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"
TARGET_DIR="$PLUGINS_DIR/$PLUGIN_ID"
BIN_DIR="$HOME/.local/bin"
CLI_TARGET="$BIN_DIR/omarchy-dlss"
APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
SHELL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"

echo "🗑 Uninstalling Omarchy DLSS 5 plugin ($PLUGIN_ID)..."

# 1. Remove CLI symlinks
rm -f "$CLI_TARGET"
rm -f "$BIN_DIR/omarchy-dlss-gui"
echo "  ✓ Removed CLI binaries"

# 2. Remove desktop application entry
rm -f "$APPS_DIR/omarchy-dlss.desktop"
update-desktop-database "$APPS_DIR" 2>/dev/null || true
echo "  ✓ Removed desktop entry"

# 3. Remove plugin folder
if [[ -d "$TARGET_DIR" ]]; then
  rm -rf "$TARGET_DIR"
  echo "  ✓ Removed plugin directory: $TARGET_DIR"
fi

# 4. Remove from shell.json
if [[ -f "$SHELL_CONFIG" ]]; then
  echo "  ⚙ Updating shell.json..."
  python3 - << 'PYEOF'
import json
from pathlib import Path

shell_file = Path.home() / ".config" / "omarchy" / "shell.json"
try:
    with open(shell_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    if "plugins" in data and isinstance(data["plugins"], list):
        data["plugins"] = [p for p in data["plugins"] if not (isinstance(p, dict) and p.get("id") == "azterisk.dlss")]

    with open(shell_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    print("     [OK] azterisk.dlss removed from shell.json")
except Exception as err:
    print(f"     [WARN] Could not update shell.json: {err}")
PYEOF
fi

# 5. Reload Omarchy shell
if command -v omarchy >/dev/null 2>&1; then
  echo "  ✓ Reloading Omarchy shell..."
  omarchy restart shell 2>/dev/null || true
elif command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins 2>/dev/null || true
fi

echo "✓ Omarchy DLSS 5 uninstalled."
