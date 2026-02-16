#!/usr/bin/env bash

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$DOTFILES_DIR/state"

mkdir -p "$STATE_DIR"

log() {
  printf '[snapshot] %s\n' "$1"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

detect_version() {
  local tool="$1"
  local output=""
  local flag

  for flag in --version version -V -v; do
    output="$("$tool" "$flag" 2>/dev/null | head -n 1 || true)"
    if [ -n "$output" ]; then
      if [[ "$output" == Warning:* || "$output" == Error:* || "$output" == error:* ]]; then
        continue
      fi
      printf '%s' "$output"
      return 0
    fi
  done

  printf 'version unknown'
}

capture_brew_state() {
  if ! has_cmd brew; then
    log "brew not found; skipping Brewfile/state capture"
    return 0
  fi

  export HOMEBREW_NO_AUTO_UPDATE=1

  log "capturing Brewfile"
  if ! brew bundle dump --force --file "$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then
    log "failed to dump Brewfile; keeping existing Brewfile as-is"
  fi

  log "capturing brew package versions"
  if ! brew list --versions 2>/dev/null | sort > "$STATE_DIR/brew-versions.txt"; then
    log "failed to capture brew versions"
  fi
  if ! brew tap 2>/dev/null | sort > "$STATE_DIR/brew-taps.txt"; then
    log "failed to capture brew taps"
  fi
}

capture_editor_state() {
  if has_cmd code; then
    log "capturing VS Code extensions"
    if ! code --list-extensions 2>/dev/null | sort > "$STATE_DIR/vscode-extensions.txt"; then
      log "failed to capture VS Code extensions"
    fi
  else
    log "code CLI not found; skipping VS Code extensions"
  fi

  if has_cmd cursor; then
    log "capturing Cursor extensions"
    if ! cursor --list-extensions 2>/dev/null | sort > "$STATE_DIR/cursor-extensions.txt"; then
      log "failed to capture Cursor extensions"
    fi
  fi
}

capture_python_state() {
  local temp_file
  temp_file="$STATE_DIR/pipx.json.tmp"

  if has_cmd pipx; then
    log "capturing pipx state"
    if pipx list --json > "$temp_file" 2>/dev/null; then
      mv "$temp_file" "$STATE_DIR/pipx.json"
    else
      rm -f "$temp_file"
      rm -f "$STATE_DIR/pipx.json"
      log "failed to capture pipx state"
    fi
  else
    log "pipx not found; skipping pipx state"
  fi
}

capture_ai_tooling_state() {
  local output_file="$STATE_DIR/ai-tools.txt"
  local tool
  local tools=(
    agent
    codex
    claude
    gemini
    aider
    ollama
    openai
    uv
    python3
    node
    npm
    nvim
    gh
  )

  {
    printf '# Snapshot generated at %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    for tool in "${tools[@]}"; do
      if has_cmd "$tool"; then
        printf '%s\t%s\n' "$tool" "$(detect_version "$tool")"
      fi
    done
  } > "$output_file"
}

capture_git_state() {
  local output_file="$STATE_DIR/git-global-config.txt"
  local temp_file="$STATE_DIR/git-global-config.raw.tmp"
  local line origin kv key value

  log "capturing global git config"
  if ! git config --global --list --show-origin > "$temp_file"; then
    rm -f "$temp_file"
    log "failed to capture global git config"
    return 0
  fi

  : > "$output_file"
  while IFS= read -r line; do
    origin="${line%%$'\t'*}"
    kv="${line#*$'\t'}"
    key="${kv%%=*}"
    value="${kv#*=}"

    # Normalize machine-specific absolute path in source location.
    origin="${origin/#file:$HOME\//file:\$HOME/}"

    # Redact known sensitive values.
    case "$key" in
      user.name|user.email|user.signingkey|credential.*|http.*extraheader|url.*.insteadOf)
        value="<redacted>"
        ;;
    esac

    printf '%s\t%s=%s\n' "$origin" "$key" "$value" >> "$output_file"
  done < "$temp_file"

  rm -f "$temp_file"
  if [ ! -s "$output_file" ]; then
    log "global git config capture produced no output"
  fi
}

capture_brew_state
capture_editor_state
capture_python_state
capture_ai_tooling_state
capture_git_state

log "snapshot complete"
