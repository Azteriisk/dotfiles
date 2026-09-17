#!/usr/bin/env python3
"""
Configuration Store & Preset Persistence for Omarchy DLSS 5.
Stores per-game preset preferences in ~/.config/omarchy/dlss/config.json
and parses active settings directly from OptiScaler.ini.
"""

import json
import re
from pathlib import Path
from typing import Dict, Any, Optional

CONFIG_PATH = Path.home() / ".config" / "omarchy" / "dlss" / "config.json"

PRESETS = {
    "quality": {
        "scale": "0.90",
        "strength": "1.2",
        "desc": "Maximum visual fidelity, 90% model resolution (Best for RTX 5070+ / 4080+)"
    },
    "balanced": {
        "scale": "0.85",
        "strength": "1.2",
        "desc": "Optimal balance of sharpness and high framerate (Recommended default)"
    },
    "performance": {
        "scale": "0.75",
        "strength": "1.0",
        "desc": "High FPS mode, 75% model resolution for heavy ray-tracing titles"
    }
}


def load_user_config() -> Dict[str, Any]:
    """
    Loads the persistent user configuration from disk.
    """
    if CONFIG_PATH.is_file():
        try:
            return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {
        "general": {
            "default_preset": "balanced",
            "allow_anti_cheat_bypass": false,
            "auto_patch_registry": true
        },
        "game_presets": {}
    }


def save_user_config(cfg: Dict[str, Any]):
    """
    Saves configuration dict back to ~/.config/omarchy/dlss/config.json.
    """
    try:
        CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
        CONFIG_PATH.write_text(json.dumps(cfg, indent=2), encoding="utf-8")
    except Exception:
        pass


def get_saved_preset(appid: str) -> Optional[str]:
    """
    Returns the user's saved preset for a specific game AppID.
    """
    cfg = load_user_config()
    return cfg.get("game_presets", {}).get(str(appid))


def save_game_preset(appid: str, preset_name: str):
    """
    Persists the user's selected preset for a specific game AppID.
    """
    cfg = load_user_config()
    presets = cfg.setdefault("game_presets", {})
    presets[str(appid)] = preset_name
    save_user_config(cfg)


def read_preset_from_ini(ini_path: Path) -> Optional[str]:
    """
    Inspects an OptiScaler.ini file to determine the active DLSS 5 preset.
    """
    if not ini_path.is_file():
        return None
    try:
        content = ini_path.read_text(encoding="utf-8", errors="ignore")
        cur_sec = None
        for line in content.splitlines():
            s = line.strip()
            if s.startswith('[') and s.endswith(']'):
                cur_sec = s.lower()
                continue
            if cur_sec == '[dlssnr]':
                m = re.match(r'^\s*WorkingScale\s*=\s*([0-9.]+)', line, re.IGNORECASE)
                if m:
                    scale = float(m.group(1))
                    if scale >= 0.88:
                        return "quality"
                    elif scale <= 0.78:
                        return "performance"
                    else:
                        return "balanced"
    except Exception:
        pass
    return None


def update_ini_preset(ini_path: Path, preset_name: str = "balanced", api: str = "dx12") -> bool:
    """
    Updates or patches an existing OptiScaler.ini with preset values using regex.
    """
    if not ini_path.is_file():
        return False

    preset = PRESETS.get(preset_name, PRESETS["balanced"])
    scale = preset["scale"]
    strength = preset["strength"]

    try:
        content = ini_path.read_text(encoding="utf-8", errors="ignore")
        lines = content.splitlines(keepends=True)
        new_lines = []
        cur_sec = None

        for line in lines:
            s = line.strip()
            if s.startswith('[') and s.endswith(']'):
                cur_sec = s.lower()

            if cur_sec == '[dlssnr]':
                if re.match(r'^\s*Enabled\s*=', line, re.IGNORECASE):
                    new_lines.append('Enabled = true\n')
                    continue
                elif re.match(r'^\s*ToggleKey\s*=', line, re.IGNORECASE):
                    new_lines.append('ToggleKey = 0x75\n')
                    continue
                elif re.match(r'^\s*TransferStrength\s*=', line, re.IGNORECASE):
                    new_lines.append(f'TransferStrength = {strength}\n')
                    continue
                elif re.match(r'^\s*ColourStrength\s*=', line, re.IGNORECASE):
                    new_lines.append('ColourStrength = 1.0\n')
                    continue
                elif re.match(r'^\s*WorkingScale\s*=', line, re.IGNORECASE):
                    new_lines.append(f'WorkingScale = {scale}\n')
                    continue
                elif re.match(r'^\s*AutoCapture\s*=', line, re.IGNORECASE):
                    new_lines.append('AutoCapture = true\n')
                    continue

            elif cur_sec == '[upscalers]':
                if re.match(r'^\s*Dx12Upscaler\s*=', line, re.IGNORECASE):
                    new_lines.append('Dx12Upscaler = dlss\n' if api == 'dx12' else 'Dx12Upscaler = auto\n')
                    continue

            new_lines.append(line)

        ini_path.write_text("".join(new_lines), encoding="utf-8")
        return True
    except Exception:
        return False
