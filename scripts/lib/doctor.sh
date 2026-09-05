#!/usr/bin/env bash
# doctor.sh - Health checks, broken symlink detection, and secret security audits

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_doctor() {
  ui_header "Running Dotfiles Doctor & Security Audit"
  local issues=0
  local warnings=0

  ui_section "1. Essential Tooling Checks"
  for tool in git rsync bash; do
    if command -v "$tool" >/dev/null 2>&1; then
      ui_success "Found essential tool: $tool"
    else
      ui_error "Missing essential tool: $tool"
      issues=$((issues + 1))
    fi
  done

  for opt in python3 jq hyprctl omarchy systemctl; do
    if command -v "$opt" >/dev/null 2>&1; then
      ui_info "Optional tool detected: $opt"
    fi
  done

  echo ""
  ui_section "2. Security & Secret Leak Audit"
  local found_sensitive=0
  # Check tracked files against forbidden patterns
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if [[ "$f" =~ xdph\.conf ]] || [[ "$f" =~ \.gitignore ]] || [[ "$f" =~ doctor\.sh ]]; then
      continue
    fi
    ui_warn "Potential sensitive filename pattern found: $f"
    found_sensitive=$((found_sensitive + 1))
    warnings=$((warnings + 1))
  done < <(cd "$DOTFILES_DIR" && git ls-files | grep -E "(id_rsa|id_ed25519|\.pem$|\.key$|\.env$)" || true)

  # Check file contents for common API tokens
  local token_hits
  token_hits="$(cd "$DOTFILES_DIR" && git grep -i -E "(ghp_[a-zA-Z0-9]{20,}|github_pat_[a-zA-Z0-9_]{20,}|AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{20,})" -- ':(exclude)scripts/lib/doctor.sh' 2>/dev/null || true)"
  if [ -n "$token_hits" ]; then
    ui_error "CRITICAL: Live API token patterns detected in repo files:"
    echo "$token_hits"
    issues=$((issues + 1))
  else
    ui_success "Zero API token leaks detected."
  fi

  echo ""
  ui_section "3. Symlink Portability Audit"
  local broken_links=0
  while IFS= read -r -d '' link; do
    [ -z "$link" ] && continue
    local link_dir target
    link_dir="$(dirname "$link")"
    target="$(readlink "$link")"

    # Test relative or absolute resolution accurately
    local resolves=false
    if [[ "$target" = /* ]]; then
      [ -e "$target" ] && resolves=true
    else
      (cd "$link_dir" && [ -e "$target" ]) && resolves=true
    fi

    # When deployed to ~/.config or ~/.local/bin, relative targets like ../../.config/... will resolve against $HOME
    if [ "$resolves" = "false" ]; then
      if [[ "$target" =~ \.\./\.\./\.config ]] && [ -e "$HOME/.config/${target#*../../.config/}" ]; then
        resolves=true
      elif [[ "$target" =~ \.local/state ]] && [ -e "$HOME/.local/state/${target#*../../.local/state/}" ]; then
        resolves=true
      fi
    fi

    if [ "$resolves" = "false" ]; then
      if [[ "$target" =~ /run/media/ ]]; then
        ui_info "External media preview link: $(basename "$link") (requires mounted drive)"
      else
        ui_warn "Dangling symlink: $link -> $target"
        broken_links=$((broken_links + 1))
        warnings=$((warnings + 1))
      fi
    fi
  done < <(find "$DOTFILES_DIR/presets" -type l -print0 2>/dev/null || true)

  if [ "$broken_links" -eq 0 ]; then
    ui_success "All managed symlinks in presets are healthy."
  fi

  echo ""
  ui_section "4. Hardcoded User Paths Check"
  local hardcoded=0
  while IFS= read -r -d '' link; do
    [ -z "$link" ] && continue
    local target
    target="$(readlink "$link")"
    if [[ "$target" =~ ^/home/ ]]; then
      ui_warn "Symlink targets absolute /home/ path: $link -> $target"
      hardcoded=$((hardcoded + 1))
      warnings=$((warnings + 1))
    fi
  done < <(find "$DOTFILES_DIR/presets" -type l -print0 2>/dev/null || true)

  if [ "$hardcoded" -eq 0 ]; then
    ui_success "Zero hardcoded user symlinks in presets."
  fi

  echo ""
  ui_section "Audit Summary"
  if [ "$issues" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    ui_success "Clean bill of health! Repository is ready for public hosting."
  elif [ "$issues" -eq 0 ]; then
    ui_warn "Passed with $warnings warning(s). No blocking security errors."
  else
    ui_error "Audit failed with $issues critical issue(s) and $warnings warning(s)."
    return 1
  fi
}
