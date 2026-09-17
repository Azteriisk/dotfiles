#!/usr/bin/env python3
"""
Steam Multi-Library & Prefix Scanner for Omarchy DLSS 5.
Discovers all installed games across all Steam libraries, maps their Proton prefixes,
identifies primary executables, and assesses DLSS 5 compatibility.
"""

import os
import re
import glob
from pathlib import Path
from typing import Dict, List, Any, Optional

from .pe_checker import inspect_pe_header, detect_anti_cheat
from .registry_patcher import check_dll_overrides
from .config_store import read_preset_from_ini, get_saved_preset

DEFAULT_STEAM_ROOT = Path.home() / ".local" / "share" / "Steam"
ALT_STEAM_ROOT = Path.home() / ".steam" / "steam"

EXCLUDE_TOOLS = [
    "Steam Linux Runtime*", "Proton*", "Steamworks*", "SteamVR*",
    "Wallpaper Engine", "Blender", "Aseprite", "Steam Controller*"
]

IGNORE_EXE_NAMES = {
    "dxsetup.exe", "vcredist_x86.exe", "vcredist_x64.exe", "vc_redist.x64.exe",
    "vc_redist.x86.exe", "oalinst.exe", "dotNetFx40_Full_setup.exe",
    "unrealcefsubprocess.exe", "crashreportclient.exe", "unitycrashhandler64.exe",
    "unitycrashhandler32.exe", "easyanticheat_eos_setup.exe", "easyanticheat_setup.exe",
    "uninstall.exe", "unins000.exe"
}


def find_steam_libraries() -> List[Path]:
    """
    Parses libraryfolders.vdf from Steam to return all active library paths.
    """
    libs = set()
    for base in [DEFAULT_STEAM_ROOT, ALT_STEAM_ROOT]:
        vdf_path = base / "steamapps" / "libraryfolders.vdf"
        if vdf_path.is_file():
            try:
                content = vdf_path.read_text(encoding="utf-8", errors="ignore")
                for match in re.finditer(r'"path"\s+"([^"]+)"', content):
                    p = Path(match.group(1)).resolve()
                    if (p / "steamapps").is_dir():
                        libs.add(p)
            except Exception:
                pass

    # Ensure default library is included if existing
    if DEFAULT_STEAM_ROOT.is_dir() and (DEFAULT_STEAM_ROOT / "steamapps").is_dir():
        libs.add(DEFAULT_STEAM_ROOT.resolve())

    return sorted(list(libs))


def parse_acf(path: Path) -> Dict[str, str]:
    """
    Parses a Steam appmanifest_*.acf file into key-value pairs.
    """
    data = {}
    try:
        content = path.read_text(encoding="utf-8", errors="ignore")
        for match in re.finditer(r'"(\w+)"\s+"([^"]*)"', content):
            data[match.group(1)] = match.group(2)
    except Exception:
        pass
    return data


def score_exe(p: Path) -> float:
    name = p.name.lower()
    path_str = str(p).lower()
    score = 0.0

    # Penalize launchers, crash reporters, redistributables
    if any(k in name for k in ["launcher", "prelauncher", "reporter", "setup", "update", "benchmark", "crash"]):
        score -= 500.0

    # Strong bonus for shipping binaries
    if "shipping" in name:
        score += 300.0

    # Strong bonus for standard 64-bit game binary directories
    if any(k in path_str for k in ["/binaries/win64/", "/bin/x64/", "/bin64/", "/x64/"]):
        score += 200.0

    # Bonus for file size (real game engines are 30MB - 150MB+, launchers are < 5MB)
    try:
        size_mb = p.stat().st_size / (1024 * 1024)
        score += min(size_mb, 200.0)
    except Exception:
        pass

    return score


def find_game_executables(game_dir: Path) -> List[Path]:
    """
    Scans a game directory for candidate primary Windows executables,
    prioritizing actual game engine binaries over launchers.
    """
    candidates = []
    if not game_dir.is_dir():
        return candidates

    for root, dirs, files in os.walk(game_dir):
        rel_depth = len(Path(root).relative_to(game_dir).parts)
        if rel_depth > 4:
            dirs.clear()
            continue

        for f in files:
            if f.lower().endswith(".exe"):
                if f.lower() not in IGNORE_EXE_NAMES:
                    candidates.append(Path(root) / f)

    # Sort candidates so the most likely game binaries (highest score) come first
    candidates.sort(key=score_exe, reverse=True)
    return candidates


def find_compat_prefix(appid: str, libraries: List[Path]) -> Optional[Path]:
    """
    Locates the Proton prefix user.reg for a given AppID across all libraries.
    """
    for lib in libraries:
        reg_candidate = lib / "steamapps" / "compatdata" / appid / "pfx" / "user.reg"
        if reg_candidate.is_file():
            return reg_candidate
    return None


def scan_games() -> List[Dict[str, Any]]:
    """
    Discovers all installed Steam games, checks their architecture, anti-cheat,
    Proton prefix, and active DLSS 5 status.
    """
    libraries = find_steam_libraries()
    games = []

    for lib in libraries:
        steamapps = lib / "steamapps"
        manifests = list(steamapps.glob("appmanifest_*.acf"))

        for mf in manifests:
            meta = parse_acf(mf)
            appid = meta.get("appid")
            name = meta.get("name")
            installdir = meta.get("installdir")

            if not appid or not name or not installdir:
                continue

            # Filter out runtime tools / Steamworks / Proton
            from fnmatch import fnmatch
            if any(fnmatch(name, pat) for pat in EXCLUDE_TOOLS):
                continue

            game_path = steamapps / "common" / installdir
            if not game_path.is_dir():
                continue

            exes = find_game_executables(game_path)
            primary_exe = exes[0] if exes else None

            # Inspect PE header
            pe_info = inspect_pe_header(primary_exe) if primary_exe else {
                "valid": False,
                "is_64bit": False,
                "pe_format": "None",
                "compatible": False,
                "reason": "No Windows .exe executable found"
            }

            # Detect anti-cheat
            ac = detect_anti_cheat(primary_exe.parent if primary_exe else game_path)

            # Locate Proton prefix
            user_reg = find_compat_prefix(appid, libraries)

            # Check DLSS 5 files in game directory
            dlss_target_dir = primary_exe.parent if primary_exe else game_path
            has_dxgi = (dlss_target_dir / "dxgi.dll").is_file() or (dlss_target_dir / "OptiScaler.dll").is_file()
            has_model = (dlss_target_dir / "nvngx_dlssnr.dll").is_file()
            has_ini = (dlss_target_dir / "OptiScaler.ini").is_file()
            has_files = has_dxgi and has_model and has_ini

            # Check registry overrides
            reg_status = check_dll_overrides(user_reg, ["dxgi"]) if user_reg else {"exists": False, "all_present": False}
            has_reg = reg_status.get("all_present", False)

            is_active = has_files and (has_reg or not user_reg)

            # Determine active preset
            active_preset = None
            if has_ini:
                active_preset = read_preset_from_ini(dlss_target_dir / "OptiScaler.ini")
            if not active_preset:
                active_preset = get_saved_preset(appid) or "balanced"

            # Compatibility verdict
            compatible = pe_info.get("is_64bit", False)
            if ac:
                compat_badge = "ANTI-CHEAT"
                status_desc = f"Protected by {ac} (Multiplayer risk)"
            elif not compatible:
                compat_badge = "32-BIT / INCOMPATIBLE"
                status_desc = pe_info.get("reason", "32-bit architecture")
            elif is_active:
                compat_badge = "ACTIVE"
                status_desc = f"DLSS 5 Neural Rendering is active ({active_preset.upper()})"
            else:
                compat_badge = "COMPATIBLE"
                status_desc = "Ready for DLSS 5 installation"

            games.append({
                "appid": appid,
                "name": name,
                "installdir": installdir,
                "game_path": str(game_path),
                "dlss_target_dir": str(dlss_target_dir),
                "primary_exe": str(primary_exe) if primary_exe else None,
                "is_64bit": pe_info.get("is_64bit", False),
                "pe_format": pe_info.get("pe_format", "Unknown"),
                "anti_cheat": ac,
                "user_reg": str(user_reg) if user_reg else None,
                "dlss5_active": is_active,
                "active_preset": active_preset,
                "has_files": has_files,
                "has_registry": has_reg,
                "compatible": compatible,
                "badge": compat_badge,
                "status_desc": status_desc
            })

    # Sort alphabetically by game name
    games.sort(key=lambda g: g["name"].lower())
    return games
