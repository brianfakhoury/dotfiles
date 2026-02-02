# dotfiles

My personal configuration files.

## What's included

- **zsh**: Shell configuration (`.zshrc`, `.zshenv`, `.zprofile`)
- **profile**: Shell profile (`.profile` - Cargo/Rust environment)
- **git**: Git configuration
- **nvim**: Neovim configuration
- **Brewfile**: Homebrew package list for reproducible setup

## Installation

Clone the repo and run the install script:

```bash
git clone https://github.com/brianfakhoury/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
./install.sh
```

The install script will:
- Back up any existing dotfiles (with `.backup` extension)
- Create symlinks from your home directory to this repo
- Set up all configurations automatically

## Structure

```
dotfiles/
├── zsh/
│   ├── zshrc
│   ├── zshenv
│   └── zprofile
├── git/
│   └── gitconfig
├── nvim/
│   └── (neovim config files)
├── profile
├── Brewfile
├── install.sh
└── README.md
```

## Notes

- Symlinks allow changes to sync automatically - edit files in the repo, changes apply immediately
- Private keys and secrets are intentionally excluded
- To update: `git pull` in the dotfiles directory
