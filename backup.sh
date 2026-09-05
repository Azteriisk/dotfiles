#!/usr/bin/env bash
# backup.sh - Sync active system configs, run secret scanner, and auto-commit
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DOTFILES_DIR/dots" backup "$@"
