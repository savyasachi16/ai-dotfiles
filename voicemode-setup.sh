#!/bin/bash
# VoiceMode setup for macOS + Linux
# Installs uv, voice-mode-install, and local STT/TTS services

set -euo pipefail

info()    { printf '  \033[34m•\033[0m %s\n' "$*"; }
success() { printf '  \033[32m✔\033[0m %s\n' "$*"; }
error()   { printf '  \033[31m✖\033[0m %s\n' "$*" >&2; }

printf '\n\033[1mVoiceMode Setup\033[0m\n'

# ── Check architecture ──────────────────────────────────────────────────────
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
  ARCH_PREFIX="arch -arm64"
  info "Detected ARM64 (Apple Silicon)"
else
  ARCH_PREFIX=""
  info "Detected $ARCH"
fi

# ── Install uv ──────────────────────────────────────────────────────────────
if ! command -v uvx &>/dev/null; then
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
else
  success "uv already installed"
fi

# ── Install portaudio (macOS) ───────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! brew list portaudio &>/dev/null; then
    info "Installing portaudio..."
    $ARCH_PREFIX brew install portaudio
  else
    success "portaudio already installed"
  fi
fi

# ── Run voice-mode-install ──────────────────────────────────────────────────
info "Running voice-mode-install..."
export PATH="$HOME/.local/bin:$PATH"
uvx voice-mode-install --yes

# ── Install Whisper (with arch fix for macOS) ───────────────────────────────
if [[ "$OSTYPE" == "darwin"* && "$ARCH" == "arm64" ]]; then
  info "Installing Whisper (ARM64)..."
  (
    export HOMEBREW_NO_AUTO_UPDATE=1
    $ARCH_PREFIX bash -c "voicemode service install whisper"
  ) || error "Whisper install failed (may need manual setup)"
else
  info "Installing Whisper..."
  voicemode service install whisper || error "Whisper install failed"
fi

# ── Verify services ─────────────────────────────────────────────────────────
success "VoiceMode setup complete"
printf '\nServices installed:\n'
voicemode service status whisper 2>/dev/null && success "Whisper (STT)" || info "Whisper (pending)"
voicemode service status kokoro 2>/dev/null && success "Kokoro (TTS)" || info "Kokoro (pending)"

printf '\nNext: Restart Claude Code, then run /voicemode:converse\n\n'
