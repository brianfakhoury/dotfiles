#!/bin/bash

# Dotfiles installation script
# Creates symlinks from home directory to dotfiles repo

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  -n, --dry-run   Print planned actions without writing files
  -h, --help      Show this help message
EOF
}

run_cmd() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '[dry-run]'
        while [ "$#" -gt 0 ]; do
            printf ' %q' "$1"
            shift
        done
        printf '\n'
        return 0
    fi
    "$@"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

echo "Installing dotfiles from $DOTFILES_DIR"
if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry-run mode enabled; no files will be modified."
fi

backup_path_for() {
    local dest="$1"
    local ts candidate index
    ts="$(date +%Y%m%d-%H%M%S)"
    candidate="${dest}.backup.${ts}"
    index=0
    while [ -e "$candidate" ] || [ -L "$candidate" ]; do
        index=$((index + 1))
        candidate="${dest}.backup.${ts}.${index}"
    done
    printf '%s' "$candidate"
}

# Function to create symlink safely
link_file() {
    local src="$1"
    local dest="$2"

    if [ ! -e "$src" ] && [ ! -L "$src" ]; then
        echo "Error: source path does not exist: $src" >&2
        return 1
    fi

    # Create parent directory if needed
    run_cmd mkdir -p "$(dirname "$dest")"

    # Skip if symlink already points to the correct source
    if [ -L "$dest" ]; then
        if [ "$(readlink "$dest")" = "$src" ]; then
            echo "Already linked: $dest -> $src"
            return 0
        fi
        run_cmd rm "$dest"
    elif [ -e "$dest" ]; then
        local backup_path
        backup_path="$(backup_path_for "$dest")"
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "Would back up existing $dest to $backup_path"
        else
            echo "Backing up existing $dest to $backup_path"
        fi
        run_cmd mv "$dest" "$backup_path"
    fi

    # Create symlink
    run_cmd ln -s "$src" "$dest"
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "Would link: $dest -> $src"
    else
        echo "Linked: $dest -> $src"
    fi
}

# Zsh config
link_file "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zsh/zshenv" "$HOME/.zshenv"
link_file "$DOTFILES_DIR/zsh/zprofile" "$HOME/.zprofile"

# Shell profile
link_file "$DOTFILES_DIR/profile" "$HOME/.profile"

# Git config
link_file "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
if [ -f "$DOTFILES_DIR/git/gitconfig.local.example" ] && [ ! -f "$HOME/.gitconfig.local" ]; then
    run_cmd cp "$DOTFILES_DIR/git/gitconfig.local.example" "$HOME/.gitconfig.local"
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "Would create: $HOME/.gitconfig.local (from gitconfig.local.example)"
    else
        echo "Created: $HOME/.gitconfig.local (from gitconfig.local.example)"
    fi
fi

# Neovim config
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# Machine-local overrides template
if [ -f "$DOTFILES_DIR/machine.local.example" ] && [ ! -f "$HOME/.machine.local" ]; then
    run_cmd cp "$DOTFILES_DIR/machine.local.example" "$HOME/.machine.local"
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "Would create: $HOME/.machine.local (from machine.local.example)"
    else
        echo "Created: $HOME/.machine.local (from machine.local.example)"
    fi
fi

echo ""
if [ "$DRY_RUN" -eq 1 ]; then
    echo "✓ Dry run complete. No files were modified."
    echo ""
    echo "Next steps:"
    echo "  1. Review planned actions above"
    echo "  2. Run ./install.sh to apply changes"
else
    echo "✓ Dotfiles installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your shell or run: source ~/.zshrc"
    echo "  2. Open nvim to install plugins"
fi
