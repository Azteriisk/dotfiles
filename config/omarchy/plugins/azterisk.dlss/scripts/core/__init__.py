"""
Omarchy DLSS 5 Core Engine Package
"""
from .pe_checker import inspect_pe_header, detect_anti_cheat
from .registry_patcher import inject_dll_overrides, remove_dll_overrides, check_dll_overrides
from .steam_scanner import scan_games
from .dlss_manager import enable_dlss5, disable_dlss5, get_game_by_query, PRESETS
