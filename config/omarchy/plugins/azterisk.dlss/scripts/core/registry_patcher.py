#!/usr/bin/env python3
"""
Proton Prefix Registry Patcher for Omarchy DLSS 5.
Safely injects and removes DLL overrides in a game's Proton prefix (user.reg)
without launching Wine commands or altering other registry entries.
"""

import os
import re
from pathlib import Path
from typing import Dict, List, Any


def inject_dll_overrides(user_reg_path: Path | str, overrides: Dict[str, str]) -> bool:
    """
    Safely injects or updates DLL overrides in a Proton prefix user.reg file.
    
    :param user_reg_path: Path to <prefix>/pfx/user.reg
    :param overrides: Dict of dll base names to mode, e.g. {"dxgi": "native,builtin"}
    """
    path = Path(user_reg_path)
    if not path.is_file():
        raise FileNotFoundError(f"Registry file not found: {path}")

    # Standardize names: lowercase, strip .dll extension
    normalized_overrides = {
        k.lower().removesuffix(".dll"): v for k, v in overrides.items()
    }

    target_section = "[Software\\Wine\\DllOverrides]"
    temp_file = path.with_suffix(".reg.new")
    
    in_target_section = False
    section_found = False
    written_keys = set()

    with open(path, "r", encoding="utf-8", errors="replace") as reg_in, \
         open(temp_file, "w", encoding="utf-8") as reg_out:

        for line in reg_in:
            stripped = line.strip()

            if stripped.startswith("["):
                if in_target_section:
                    # Leaving target section: append any missing overrides
                    for dll, mode in normalized_overrides.items():
                        if dll not in written_keys:
                            reg_out.write(f'"{dll}"="{mode}"\n')
                            written_keys.add(dll)
                    in_target_section = False

                if stripped.startswith(target_section):
                    in_target_section = True
                    section_found = True

            elif in_target_section:
                match = re.match(r'^"([^"]+)"\s*=', stripped)
                if match:
                    dll_key = match.group(1).lower()
                    if dll_key in normalized_overrides:
                        new_mode = normalized_overrides[dll_key]
                        reg_out.write(f'"{dll_key}"="{new_mode}"\n')
                        written_keys.add(dll_key)
                        continue

            reg_out.write(line)

        # File ended
        if in_target_section:
            for dll, mode in normalized_overrides.items():
                if dll not in written_keys:
                    reg_out.write(f'"{dll}"="{mode}"\n')
                    written_keys.add(dll)
        elif not section_found:
            reg_out.write(f"\n{target_section}\n")
            for dll, mode in normalized_overrides.items():
                reg_out.write(f'"{dll}"="{mode}"\n')

    # Atomic swap with backup
    backup_file = path.with_suffix(".reg.old")
    if backup_file.exists():
        backup_file.unlink()
    path.rename(backup_file)
    temp_file.replace(path)
    return True


def remove_dll_overrides(user_reg_path: Path | str, keys: List[str]) -> bool:
    """
    Safely removes specific DLL override keys from [Software\\Wine\\DllOverrides].
    """
    path = Path(user_reg_path)
    if not path.is_file():
        return False

    normalized_keys = {k.lower().removesuffix(".dll") for k in keys}
    target_section = "[Software\\Wine\\DllOverrides]"
    temp_file = path.with_suffix(".reg.new")

    in_target_section = False

    with open(path, "r", encoding="utf-8", errors="replace") as reg_in, \
         open(temp_file, "w", encoding="utf-8") as reg_out:

        for line in reg_in:
            stripped = line.strip()

            if stripped.startswith("["):
                if stripped.startswith(target_section):
                    in_target_section = True
                else:
                    in_target_section = False

            elif in_target_section:
                match = re.match(r'^"([^"]+)"\s*=', stripped)
                if match:
                    dll_key = match.group(1).lower()
                    if dll_key in normalized_keys:
                        # Skip this line (deleting the override)
                        continue

            reg_out.write(line)

    backup_file = path.with_suffix(".reg.old")
    if backup_file.exists():
        backup_file.unlink()
    path.rename(backup_file)
    temp_file.replace(path)
    return True


def check_dll_overrides(user_reg_path: Path | str, keys: List[str]) -> Dict[str, Any]:
    """
    Checks the status of specific DLL overrides in a Proton prefix.
    """
    path = Path(user_reg_path)
    if not path.is_file():
        return {"exists": False, "overrides": {}}

    normalized_keys = {k.lower().removesuffix(".dll") for k in keys}
    target_section = "[Software\\Wine\\DllOverrides]"
    in_target_section = False
    found = {}

    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("["):
                in_target_section = stripped.startswith(target_section)
            elif in_target_section:
                match = re.match(r'^"([^"]+)"\s*=\s*"([^"]*)"', stripped)
                if match:
                    k, v = match.group(1).lower(), match.group(2)
                    if k in normalized_keys:
                        found[k] = v

    return {
        "exists": True,
        "overrides": found,
        "all_present": all(k in found for k in normalized_keys)
    }
