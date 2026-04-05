#!/usr/bin/env bash
# setup.sh — wire up Claude Code dotfiles via symlinks
# Safe to run multiple times (idempotent).
# Usage: bash setup.sh [--force]

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$CLAUDE_DIR/.dotfiles-backup-$BACKUP_TS"
BACKUP_USED=false

# Counters for summary
COPIED=()
SYMLINKED=()
BACKED_UP=()
SKIPPED=()

# ── helpers ──────────────────────────────────────────────────────────────────

info()    { printf '  \033[34m•\033[0m %s\n' "$*"; }
success() { printf '  \033[32m✔\033[0m %s\n' "$*"; }
warn()    { printf '  \033[33m!\033[0m %s\n' "$*"; }
error()   { printf '  \033[31m✖\033[0m %s\n' "$*" >&2; }

backup_if_needed() {
  local target="$1"
  # Nothing to back up if target doesn't exist
  [[ -e "$target" || -L "$target" ]] || return 0
  # Already a symlink into our dotfiles — skip
  if [[ -L "$target" ]]; then
    local link_dest
    link_dest="$(readlink "$target")"
    if [[ "$link_dest" == "$DOTFILES_DIR"* ]]; then
      return 0
    fi
  fi
  # Back up
  mkdir -p "$BACKUP_DIR"
  mv "$target" "$BACKUP_DIR/"
  BACKUP_USED=true
  BACKED_UP+=("$(basename "$target")")
}

make_symlink() {
  local src="$1"
  local dest="$2"
  # Source must exist in the repo
  if [[ ! -e "$src" ]]; then
    SKIPPED+=("$(basename "$src") (not in repo yet)")
    return 0
  fi
  # Already correctly symlinked — skip (and avoid ln creating inside a dir symlink)
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    SKIPPED+=("$(basename "$dest") (already symlinked)")
    return 0
  fi
  backup_if_needed "$dest"
  # Remove existing symlink before recreating — on macOS, ln -sf on a dir symlink
  # creates a new symlink *inside* the target dir instead of replacing it.
  [[ -L "$dest" ]] && rm -f "$dest"
  ln -s "$src" "$dest"
  SYMLINKED+=("$(basename "$dest")")
}

# ── guards ────────────────────────────────────────────────────────────────────

if [[ "${EUID:-$(id -u)}" -eq 0 ]] && [[ "${1:-}" != "--force" ]]; then
  error "Running as root. Use --force to override (not recommended)."
  exit 1
fi

# ── OS detection ──────────────────────────────────────────────────────────────

OS="$(uname -s)"
case "$OS" in
  Darwin) SED_INPLACE=(-i '') ;;
  Linux)  SED_INPLACE=(-i)    ;;
  *)
    warn "Unknown OS '$OS' — defaulting to GNU sed behavior."
    SED_INPLACE=(-i)
    ;;
esac

# ── setup ─────────────────────────────────────────────────────────────────────

printf '\n\033[1mClaude Code dotfiles setup\033[0m\n'
printf 'Dotfiles: %s\n' "$DOTFILES_DIR"
printf 'Target:   %s\n\n' "$CLAUDE_DIR"

mkdir -p "$CLAUDE_DIR"

# ── settings.json (copy, not symlink — see Claude Code bugs #764 / #3575) ────

SETTINGS_TPL="$DOTFILES_DIR/settings.json.tpl"
SETTINGS_DEST="$CLAUDE_DIR/settings.json"

# Build expected content by substituting @@CLAUDE_DIR@@
EXPECTED_SETTINGS="$(sed "s|@@CLAUDE_DIR@@|${CLAUDE_DIR}|g" "$SETTINGS_TPL")"
ACTUAL_SETTINGS="$(cat "$SETTINGS_DEST" 2>/dev/null || true)"

if [[ "$EXPECTED_SETTINGS" == "$ACTUAL_SETTINGS" ]]; then
  SKIPPED+=("settings.json (already up to date)")
else
  # Back up only if the existing file isn't our own output
  if [[ -e "$SETTINGS_DEST" && "$ACTUAL_SETTINGS" != "$EXPECTED_SETTINGS" ]]; then
    backup_if_needed "$SETTINGS_DEST"
  fi
  printf '%s\n' "$EXPECTED_SETTINGS" > "$SETTINGS_DEST"
  COPIED+=("settings.json")
fi

# ── symlinks ──────────────────────────────────────────────────────────────────

# Individual files
for item in statusline-command.sh CLAUDE.md; do
  make_symlink "$DOTFILES_DIR/$item" "$CLAUDE_DIR/$item"
done

# Directories (symlink the whole dir so new files appear automatically)
for dir in commands skills hooks; do
  src="$DOTFILES_DIR/$dir"
  dest="$CLAUDE_DIR/$dir"
  if [[ ! -d "$src" ]]; then
    SKIPPED+=("$dir/ (not in repo)")
    continue
  fi
  # Already correctly symlinked — skip
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    SKIPPED+=("$dir/ (already symlinked)")
    continue
  fi
  backup_if_needed "$dest"
  [[ -L "$dest" ]] && rm -f "$dest"
  ln -s "$src" "$dest"
  SYMLINKED+=("$dir/")
done

# ── summary ───────────────────────────────────────────────────────────────────

printf '\n\033[1mSummary\033[0m\n'

if [[ ${#COPIED[@]} -gt 0 ]]; then
  for f in "${COPIED[@]}"; do success "Copied:    $f"; done
fi
if [[ ${#SYMLINKED[@]} -gt 0 ]]; then
  for f in "${SYMLINKED[@]}"; do success "Symlinked: $f"; done
fi
if [[ ${#BACKED_UP[@]} -gt 0 ]]; then
  for f in "${BACKED_UP[@]}"; do warn "Backed up: $f  →  $BACKUP_DIR/"; done
fi
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  for f in "${SKIPPED[@]}"; do info "Skipped:   $f"; done
fi

if [[ ${#COPIED[@]} -eq 0 && ${#SYMLINKED[@]} -eq 0 ]]; then
  printf '\nNothing to do — already up to date.\n\n'
else
  printf '\nDone. Claude Code settings are live.\n\n'
fi
