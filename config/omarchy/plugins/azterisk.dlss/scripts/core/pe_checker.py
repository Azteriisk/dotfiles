#!/usr/bin/env python3
"""
PE & Compatibility Inspector for Omarchy DLSS 5.
Reads Portable Executable (PE) headers in pure Python to detect 64-bit architecture
and scans directory contexts for known anti-cheat systems. Zero external dependencies.
"""

import os
import struct
from pathlib import Path
from typing import Dict, Any, Optional

ANTI_CHEAT_PATTERNS = {
    "EasyAntiCheat": [
        "start_protected_game.exe",
        "easyanticheat",
        "easyanticheat_x64.dll",
        "easyanticheat_eos_setup.exe",
    ],
    "BattlEye": [
        "beservice.exe",
        "battleye",
        "beloader.exe",
    ],
    "Vanguard": [
        "vgk.sys",
        "vgc.exe",
    ],
    "Ricochet": [
        "randgrid.sys",
    ]
}


def inspect_pe_header(filepath: Path | str) -> Dict[str, Any]:
    """
    Inspects PE executable headers using Python's standard struct module.
    Accurately identifies PE32 (32-bit) vs PE32+ (64-bit) binaries.
    """
    path = Path(filepath)
    if not path.is_file():
        return {
            "valid": False,
            "error": f"File not found: {path}",
            "is_64bit": False,
            "pe_format": "Unknown",
            "compatible": False,
            "reason": "Executable file does not exist",
        }

    try:
        with open(path, "rb") as f:
            dos_header = f.read(64)
            if len(dos_header) < 64 or dos_header[:2] != b"MZ":
                return {
                    "valid": False,
                    "error": "Not a valid MZ/DOS executable",
                    "is_64bit": False,
                    "pe_format": "Non-PE",
                    "compatible": False,
                    "reason": "Not a valid Windows executable binary",
                }

            # e_lfanew offset is at DOS header byte 0x3C (uint32 little-endian)
            e_lfanew = struct.unpack_from("<I", dos_header, 0x3C)[0]

            # Seek to PE signature and read:
            # PE Signature (4 bytes) + COFF File Header (20 bytes) + Optional Header Magic (2 bytes) = 26 bytes
            f.seek(e_lfanew)
            pe_block = f.read(26)
            if len(pe_block) < 26 or pe_block[:4] != b"PE\x00\x00":
                return {
                    "valid": False,
                    "error": "Not a valid PE header",
                    "is_64bit": False,
                    "pe_format": "Corrupt-PE",
                    "compatible": False,
                    "reason": "Invalid or truncated PE signature",
                }

            machine, n_sections, timedatestamp = struct.unpack_from("<HHI", pe_block, 4)
            opt_magic = struct.unpack_from("<H", pe_block, 24)[0]

            machine_names = {
                0x014C: "IMAGE_FILE_MACHINE_I386 (x86 32-bit)",
                0x8664: "IMAGE_FILE_MACHINE_AMD64 (x64 64-bit)",
                0xAA64: "IMAGE_FILE_MACHINE_ARM64 (ARM64 64-bit)",
                0x01C0: "IMAGE_FILE_MACHINE_ARM (ARM 32-bit)",
            }

            is_64bit = (opt_magic == 0x20B)
            if is_64bit:
                pe_format = "PE32+ (64-bit)"
                compatible = True
                reason = "Native 64-bit executable"
            elif opt_magic == 0x10B:
                pe_format = "PE32 (32-bit)"
                compatible = False
                reason = "Legacy 32-bit engine (DLSS 5 requires 64-bit architecture)"
            else:
                pe_format = f"Unknown (0x{opt_magic:04X})"
                compatible = False
                reason = f"Unsupported PE magic format: 0x{opt_magic:04X}"

            return {
                "valid": True,
                "is_64bit": is_64bit,
                "pe_format": pe_format,
                "machine": hex(machine),
                "machine_name": machine_names.get(machine, f"Unknown (0x{machine:04X})"),
                "compatible": compatible,
                "reason": reason,
                "sections_count": n_sections,
            }
    except Exception as e:
        return {
            "valid": False,
            "error": str(e),
            "is_64bit": False,
            "pe_format": "Error",
            "compatible": False,
            "reason": f"Inspection exception: {e}",
        }


def detect_anti_cheat(directory: Path | str) -> Optional[str]:
    """
    Inspects a directory for anti-cheat executables and drivers.
    Returns the name of the anti-cheat system if found, else None.
    """
    dir_path = Path(directory)
    if not dir_path.is_dir():
        return None

    try:
        candidate_files = set()
        for root, dirs, files in os.walk(dir_path):
            rel_depth = len(Path(root).relative_to(dir_path).parts)
            if rel_depth > 2:
                dirs.clear()
                continue
            for f in files:
                candidate_files.add(f.lower())

        for ac_name, patterns in ANTI_CHEAT_PATTERNS.items():
            for pat in patterns:
                for candidate in candidate_files:
                    if pat in candidate:
                        return ac_name
    except Exception:
        pass

    return None
