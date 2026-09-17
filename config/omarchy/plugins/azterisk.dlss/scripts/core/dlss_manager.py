#!/usr/bin/env python3
"""
DLSS 5 Asset & Lifecycle Manager for Omarchy.
Deploys OptiScaler DLSS-NR assets, writes preset-tuned configuration inis,
and synchronizes Wine prefix registry overrides.
"""

import os
import shutil
from pathlib import Path
from typing import Dict, Any, Optional

from .steam_scanner import scan_games
from .registry_patcher import inject_dll_overrides, remove_dll_overrides, check_dll_overrides
from .config_store import PRESETS, save_game_preset, update_ini_preset

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
ASSETS_BIN = PROJECT_ROOT / "assets" / "bin"
ASSETS_TEMPLATE = PROJECT_ROOT / "assets" / "templates" / "OptiScaler.ini"

CORE_FILES = [
    "dxgi.dll",
    "nvngx_dlssnr.dll",
    "nvngx.dll_dlssnr.dll",
    "d3dcompiler_47.dll"
]


def get_game_by_query(query: str) -> Optional[Dict[str, Any]]:
    """
    Finds an installed game by AppID or case-insensitive name match.
    """
    games = scan_games()
    query_clean = str(query).strip().lower()

    # Exact AppID match
    for g in games:
        if str(g["appid"]) == query_clean:
            return g

    # Exact name match
    for g in games:
        if g["name"].lower() == query_clean:
            return g

    # Substring match
    for g in games:
        if query_clean in g["name"].lower():
            return g

    return None


def link_or_copy(src: Path, dst: Path) -> str:
    """
    Creates a symlink from src to dst. If cross-device or permission fails,
    falls back to copying.
    """
    if dst.is_symlink() or dst.is_file():
        dst.unlink()
    elif dst.is_dir():
        shutil.rmtree(dst)

    try:
        dst.symlink_to(src)
        return "symlink"
    except Exception:
        if src.is_dir():
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)
        return "copy"


def generate_ini(dst_path: Path, preset_name: str = "balanced", api: str = "dx12") -> bool:
    """
    Generates or patches OptiScaler.ini with preset values.
    """
    if not dst_path.is_file():
        if not ASSETS_TEMPLATE.is_file():
            return False
        shutil.copy2(ASSETS_TEMPLATE, dst_path)

    return update_ini_preset(dst_path, preset_name=preset_name, api=api)


def update_game_preset(game: Dict[str, Any], preset_name: str) -> bool:
    """
    Updates the preset for a game: saves preference and if DLSS 5 is installed,
    updates OptiScaler.ini in place.
    """
    appid = str(game["appid"])
    save_game_preset(appid, preset_name)

    target_dir = Path(game["dlss_target_dir"])
    ini_path = target_dir / "OptiScaler.ini"
    if ini_path.is_file():
        return update_ini_preset(ini_path, preset_name=preset_name)
    return True


def enable_dlss5(game: Dict[str, Any], preset: str = "balanced", force: bool = False) -> Dict[str, Any]:
    """
    Installs and activates DLSS 5 for the given game.
    """
    if not game["is_64bit"] and not force:
        return {
            "success": False,
            "error": f"Cannot enable DLSS 5: {game['status_desc']}"
        }

    target_dir = Path(game["dlss_target_dir"])
    if not target_dir.is_dir():
        return {
            "success": False,
            "error": f"Target directory not found: {target_dir}"
        }

    linked_methods = {}

    # Deploy core DLL files
    for fname in CORE_FILES:
        src = ASSETS_BIN / fname
        dst = target_dir / fname
        if src.exists():
            method = link_or_copy(src, dst)
            linked_methods[fname] = method

    # Deploy OptiScaler folder if present
    optiscaler_dir = ASSETS_BIN / "OptiScaler"
    if optiscaler_dir.is_dir():
        dst_opt = target_dir / "OptiScaler"
        method = link_or_copy(optiscaler_dir, dst_opt)
        linked_methods["OptiScaler/"] = method

    # Generate OptiScaler.ini with chosen preset
    ini_path = target_dir / "OptiScaler.ini"
    generate_ini(ini_path, preset_name=preset)
    linked_methods["OptiScaler.ini"] = "generated"

    # Remember preset in config
    save_game_preset(str(game["appid"]), preset)

    # Inject Proton prefix registry override
    reg_applied = False
    if game["user_reg"]:
        try:
            inject_dll_overrides(game["user_reg"], {
                "dxgi": "native,builtin",
                "d3dcompiler_47": "native,builtin"
            })
            reg_applied = True
        except Exception as e:
            reg_applied = False

    return {
        "success": True,
        "preset": preset,
        "files": linked_methods,
        "registry_applied": reg_applied,
        "target_dir": str(target_dir)
    }


def disable_dlss5(game: Dict[str, Any]) -> Dict[str, Any]:
    """
    Completely removes DLSS 5 files and restores the pristine Proton prefix.
    """
    target_dir = Path(game["dlss_target_dir"])
    removed_files = []

    files_to_remove = CORE_FILES + ["OptiScaler.ini", "OptiScaler.log", "OptiScaler.dll"]
    for fname in files_to_remove:
        p = target_dir / fname
        if p.is_symlink() or p.is_file():
            p.unlink()
            removed_files.append(fname)

    opt_dir = target_dir / "OptiScaler"
    if opt_dir.is_symlink():
        opt_dir.unlink()
        removed_files.append("OptiScaler/")
    elif opt_dir.is_dir():
        shutil.rmtree(opt_dir)
        removed_files.append("OptiScaler/")

    # Remove registry overrides
    reg_reverted = False
    if game["user_reg"]:
        try:
            remove_dll_overrides(game["user_reg"], ["dxgi", "d3dcompiler_47"])
            reg_reverted = True
        except Exception:
            pass

    return {
        "success": True,
        "removed_files": removed_files,
        "registry_reverted": reg_reverted
    }
