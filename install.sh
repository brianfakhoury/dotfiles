#!/bin/bash

# Dotfiles installation script
# Creates symlinks from home directory to dotfiles repo

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Function to create symlink safely
link_file() {
    local src="$1"
    local dest="$2"
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$dest")"
    
    # Backup existing file if it exists and isn't already a symlink
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "Backing up existing $dest to $dest.backup"
        mv "$dest" "$dest.backup"
    fi
    
    # Remove existing symlink if present
    if [ -L "$dest" ]; then
        rm "$dest"
    fi
    
    # Create symlink
    ln -s "$src" "$dest"
    echo "Linked: $dest -> $src"
}

# Zsh config
link_file "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zsh/zshenv" "$HOME/.zshenv"
link_file "$DOTFILES_DIR/zsh/zprofile" "$HOME/.zprofile"

# Shell profile
link_file "$DOTFILES_DIR/profile" "$HOME/.profile"

# Git config
link_file "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

# Neovim config
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

echo ""
echo "✓ Dotfiles installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.zshrc"
echo "  2. Open nvim to install plugins"
