#!/usr/bin/env bash
# ui.sh - Terminal UI styling, colors, and prompt utilities for dots

# Detect color support
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
  BOLD="$(tput bold 2>/dev/null || true)"
  DIM="$(tput dim 2>/dev/null || true)"
  RESET="$(tput sgr0 2>/dev/null || true)"
  RED="$(tput setaf 1 2>/dev/null || true)"
  GREEN="$(tput setaf 2 2>/dev/null || true)"
  YELLOW="$(tput setaf 3 2>/dev/null || true)"
  BLUE="$(tput setaf 4 2>/dev/null || true)"
  MAGENTA="$(tput setaf 5 2>/dev/null || true)"
  CYAN="$(tput setaf 6 2>/dev/null || true)"
  WHITE="$(tput setaf 7 2>/dev/null || true)"
else
  BOLD=""
  DIM=""
  RESET=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  MAGENTA=""
  CYAN=""
  WHITE=""
fi

ui_header() {
  local title="$1"
  echo -e "\n${BOLD}${CYAN}==>${RESET} ${BOLD}${title}${RESET}"
}

ui_section() {
  local title="$1"
  echo -e "${BOLD}${BLUE}::${RESET} ${BOLD}${title}${RESET}"
}

ui_info() {
  echo -e "  ${DIM}ℹ${RESET}  $*"
}

ui_step() {
  echo -e "  ${CYAN}➜${RESET}  $*"
}

ui_success() {
  echo -e "  ${GREEN}✔${RESET}  ${BOLD}$*${RESET}"
}

ui_warn() {
  echo -e "  ${YELLOW}▲${RESET}  ${YELLOW}$*${RESET}"
}

ui_error() {
  echo -e "  ${RED}✖${RESET}  ${RED}${BOLD}$*${RESET}" >&2
}

ui_fatal() {
  ui_error "$*"
  exit 1
}

ui_banner() {
  echo -e "${CYAN}${BOLD}"
  cat << "BANNER"
     ___       __       _____ __         
 ___/ /____  / /_  ___/ / _//_/ ___ ___ 
/ _  / _ \ \/ / /_/ _  / _// / / -_|_-< 
\_,_/\___/\__/\__/\_,_/_/ /_/  \__/___/ 
BANNER
  echo -e "${RESET}${DIM}  Multi-Preset System & Sync Framework${RESET}\n"
}

# Prompt for confirmation (returns 0 for yes, 1 for no)
ui_confirm() {
  local prompt="$1"
  local default="${2:-Y}"
  local reply

  if [ "$default" = "Y" ]; then
    read -r -p "$(echo -e "  ${YELLOW}?${RESET} ${BOLD}${prompt}${RESET} [Y/n]: ")" reply
    reply="${reply:-Y}"
    [[ "$reply" =~ ^[Yy]$ ]] && return 0 || return 1
  else
    read -r -p "$(echo -e "  ${YELLOW}?${RESET} ${BOLD}${prompt}${RESET} [y/N]: ")" reply
    reply="${reply:-N}"
    [[ "$reply" =~ ^[Yy]$ ]] && return 0 || return 1
  fi
}
