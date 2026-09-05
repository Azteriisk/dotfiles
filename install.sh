#!/usr/bin/env bash
# install.sh - Interactive dotfiles installer and cross-machine bootstrapper
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DOTFILES_DIR/dots" install "$@"
