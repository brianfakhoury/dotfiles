#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SKIP_BREW=0
SKIP_NVIM=0
SKIP_VERIFY=0
INSTALL_HOMEBREW=0

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap.sh [options]

Options:
  --skip-brew           Skip Homebrew bundle install
  --skip-nvim           Skip Neovim plugin sync
  --skip-verify         Skip post-bootstrap verification
  --install-homebrew    Install Homebrew automatically if missing (macOS only)
  -h, --help            Show this help
EOF
}

log() {
  printf '[bootstrap] %s\n' "$1"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

install_homebrew() {
  if [ "$(uname -s)" != "Darwin" ]; then
    log "automatic Homebrew install is only supported on macOS"
    return 1
  fi

  log "installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-brew) SKIP_BREW=1 ;;
    --skip-nvim) SKIP_NVIM=1 ;;
    --skip-verify) SKIP_VERIFY=1 ;;
    --install-homebrew) INSTALL_HOMEBREW=1 ;;
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

if [ "$SKIP_BREW" -eq 0 ] && ! has_cmd brew; then
  if [ "$INSTALL_HOMEBREW" -eq 1 ]; then
    install_homebrew
  else
    cat <<'EOF' >&2
[bootstrap] Homebrew is not installed.
Install it with:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
Or rerun this script with --install-homebrew.
EOF
    exit 1
  fi
fi

if [ "$SKIP_BREW" -eq 0 ]; then
  log "installing Brewfile dependencies"
  brew bundle --file "$DOTFILES_DIR/Brewfile"
fi

log "linking dotfiles"
"$DOTFILES_DIR/install.sh"

if [ "$SKIP_NVIM" -eq 0 ] && has_cmd nvim; then
  log "syncing Neovim plugins"
  nvim --headless '+Lazy! sync' +qa || log "neovim sync failed; open nvim manually to finish plugin install"
fi

if [ ! -f "$HOME/.machine.local" ]; then
  cp "$DOTFILES_DIR/machine.local.example" "$HOME/.machine.local"
  log "created $HOME/.machine.local from template"
fi

if [ "$SKIP_VERIFY" -eq 0 ]; then
  log "running verification checks"
  "$DOTFILES_DIR/scripts/verify.sh" --quick
fi

cat <<'EOF'
[bootstrap] Complete.
Next steps:
  1. Edit ~/.machine.local for host-specific environment values.
  2. Open nvim once to verify plugins and language servers.
  3. Run scripts/snapshot.sh and commit generated state files.
EOF
