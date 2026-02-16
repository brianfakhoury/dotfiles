#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUICK=0
FAILURES=0

usage() {
  cat <<'EOF'
Usage: scripts/verify.sh [options]

Options:
  --quick      Skip temp-home smoke test
  -h, --help   Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --quick) QUICK=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

log() {
  printf '[verify] %s\n' "$1"
}

fail() {
  printf '[verify] FAIL: %s\n' "$1" >&2
  FAILURES=$((FAILURES + 1))
}

warn() {
  printf '[verify] WARN: %s\n' "$1" >&2
}

check_symlink() {
  local destination="$1"
  local expected_target="$2"

  if [ ! -L "$destination" ]; then
    fail "$destination is not a symlink"
    return
  fi

  local actual_target
  actual_target="$(readlink "$destination")"
  if [ "$actual_target" != "$expected_target" ]; then
    fail "$destination points to $actual_target (expected $expected_target)"
  fi
}

log "running shell syntax checks"
bash -n "$DOTFILES_DIR/install.sh" "$DOTFILES_DIR/scripts/bootstrap.sh" "$DOTFILES_DIR/scripts/snapshot.sh" "$DOTFILES_DIR/scripts/verify.sh"
zsh -n "$DOTFILES_DIR/zsh/zprofile" "$DOTFILES_DIR/zsh/zshenv" "$DOTFILES_DIR/zsh/zshrc"

log "checking repo symlink installation in \$HOME"
check_symlink "$HOME/.zshrc" "$DOTFILES_DIR/zsh/zshrc"
check_symlink "$HOME/.zshenv" "$DOTFILES_DIR/zsh/zshenv"
check_symlink "$HOME/.zprofile" "$DOTFILES_DIR/zsh/zprofile"
check_symlink "$HOME/.profile" "$DOTFILES_DIR/profile"
check_symlink "$HOME/.gitconfig" "$DOTFILES_DIR/git/gitconfig"
check_symlink "$HOME/.config/nvim" "$DOTFILES_DIR/nvim"

if [ ! -f "$HOME/.machine.local" ]; then
  warn "$HOME/.machine.local is missing (copy machine.local.example or rerun install.sh)"
fi

if [ "$QUICK" -eq 0 ]; then
  log "running temp-home smoke test"
  TEMP_HOME="$(mktemp -d)"
  trap 'rm -rf "$TEMP_HOME"' EXIT

  HOME="$TEMP_HOME" "$DOTFILES_DIR/install.sh" >/tmp/dotfiles-verify-install.log 2>&1

  STARTUP_LOG="/tmp/dotfiles-verify-zsh.log"
  HOME="$TEMP_HOME" PATH="/usr/bin:/bin:/usr/sbin:/sbin" zsh -lic 'echo startup-ok' >"$STARTUP_LOG" 2>&1 || true

  if ! grep -q "startup-ok" "$STARTUP_LOG"; then
    fail "zsh startup smoke test failed (see $STARTUP_LOG)"
  fi

  if grep -Eqi "no such file|command not found" "$STARTUP_LOG"; then
    fail "zsh startup emitted missing-command/path errors (see $STARTUP_LOG)"
  fi
fi

if [ "$FAILURES" -gt 0 ]; then
  printf '[verify] completed with %s failure(s)\n' "$FAILURES" >&2
  exit 1
fi

log "all checks passed"
