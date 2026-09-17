# Omarchy DLSS 5 (`azterisk.dlss`)

> Automated, zero-friction **NVIDIA DLSS 5 Neural Rendering (DLSS-NR)** manager and desktop plugin for the **Omarchy Desktop Shell**. Enables DLSS 5 across compatible Steam Proton games with a single click—no terminal required, no DLL copying, and zero manual Steam launch option editing.

---

## 🌟 Highlights

- **Zero Steam Launch Options**: Eliminates typing `WINEDLLOVERRIDES="dxgi=n,b" %command%`. Directly and safely patches the game's Proton prefix Wine registry (`user.reg`).
- **Sleek Libadwaita / GTK4 GUI (`omarchy-dlss-gui`)**: Beautiful modern desktop app with instant search, status badges, preset selection, and 1-click toggle switches.
- **Quickshell Bar Widget (`BarWidget.qml` & `Service.qml`)**: Native Omarchy top-bar widget with active game indicators, live status counter, and quick-launch menu.
- **Pure Python Architecture Validator**: Reads PE headers via Python `struct` to detect 64-bit (`PE32+`) vs 32-bit (`PE32`) binaries. Prevents crashes (`0xC000007B`) in legacy titles with friendly explanations.
- **Anti-Cheat Safety Guardrails**: Detects EasyAntiCheat, BattlEye, and Ricochet in game directories. Blocks accidental injection in multiplayer games with confirmation warnings.
- **Central Asset Depot**: Keeps a single vetted copy of the 165MB neural weights and OptiScaler runtime. Symlinks assets directly to games, saving disk space and allowing 1-click platform updates.
- **Clean 1-Click Rollback**: Removes all injected symlinks/files and restores pristine stock Proton prefix registry with one click.

---

## 🚀 Installation

Run the all-in-one installer:

```bash
cd ~/Projects/omarchy-dlss
./install.sh
```

The installer will:
1. Copy plugin files to `~/.config/omarchy/plugins/azterisk.dlss/`.
2. Symlink CLI binaries to `~/.local/bin/omarchy-dlss` and `~/.local/bin/omarchy-dlss-gui`.
3. Register the desktop entry in your application launcher (`Omarchy DLSS 5`).
4. Register the plugin service in `~/.config/omarchy/shell.json`.
5. Reload the Omarchy shell.

---

## 🎮 Usage

### 1. Graphical Application (GUI)
Launch **"Omarchy DLSS 5"** from the Omarchy Menu / App Launcher, or run:
```bash
omarchy-dlss gui
```
- Toggle switch **ON** for any compatible game.
- Select your preset:
  - **Balanced (Recommended)**: `WorkingScale=0.85` — Optimal blend of high framerate and pristine sharpness.
  - **Quality (RTX 5070+)**: `WorkingScale=0.90` — Maximum neural reconstruction fidelity.
  - **Performance**: `WorkingScale=0.75` — High FPS mode for heavy ray-tracing titles.
- Launch your game directly in Steam!

### 2. Interactive Terminal Menu
For quick keyboard-driven selection:
```bash
omarchy-dlss menu
```

### 3. CLI Commands
```bash
# List all discovered Steam games with compatibility badges
omarchy-dlss list

# Enable DLSS 5 for a game (by name or AppID)
omarchy-dlss enable "Ghostrunner 2" --preset quality
omarchy-dlss enable 1091500 --preset balanced

# Disable DLSS 5 and restore game to stock
omarchy-dlss disable "Ghostrunner 2"

# View detailed health check for a game
omarchy-dlss status "Cyberpunk 2077"

# Emit JSON data (used by Quickshell services)
omarchy-dlss json
```

---

## 🛡 Compatibility & Safety

| Engine / Platform | Status | Behavior |
|---|---|---|
| **64-bit DirectX 12 / Vulkan** | ✅ Compatible | 1-Click Enable. DX12 upscaler routed to DLSS-NR. |
| **64-bit DirectX 11** | ✅ Compatible | Deployed with OptiScaler DX11-to-Vulkan bridge. |
| **32-bit Legacy (e.g. BioShock Infinite)** | ❌ Incompatible | Blocked automatically. Explains 32-bit limitation without crashing. |
| **Multiplayer Anti-Cheat (EAC / BattlEye)** | ⚠️ Protected | Warns user of ban risks; requires `--force` or GUI confirmation. |

---

## 📁 Repository Structure

```
omarchy-dlss/
├── manifest.json              # Omarchy shell plugin manifest (azterisk.dlss)
├── Service.qml                # Headless background Quickshell service
├── BarWidget.qml              # Omarchy top-bar widget
├── config.default.json        # Default configuration template
├── omarchy-dlss.desktop       # Desktop application launcher
├── install.sh                 # User-space installer
├── uninstall.sh               # Clean uninstaller
├── PKGBUILD                   # Arch Linux system package specification
├── assets/
│   ├── bin/                   # OptiScaler runtime, ShortFuse neural model, shims
│   └── templates/             # Tuned OptiScaler.ini template
└── scripts/
    ├── omarchy-dlss           # Main CLI driver
    ├── omarchy-dlss-gui       # Libadwaita / GTK4 desktop GUI
    ├── omarchy-dlss-menu      # Interactive terminal selector
    └── core/
        ├── pe_checker.py      # Pure-Python struct PE32/PE32+ & Anti-Cheat validator
        ├── steam_scanner.py   # Multi-library & Proton prefix discoverer
        ├── registry_patcher.py# Atomic user.reg DLL override patcher
        └── dlss_manager.py    # Symlink manager, preset builder, lifecycle coordinator
```
