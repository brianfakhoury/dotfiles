# dotfiles

Personal machine configuration focused on deterministic rebuilds and state capture.

## What's included

- **zsh**: Shell configuration (`.zshrc`, `.zshenv`, `.zprofile`)
- **profile**: Shell profile (`.profile` - Cargo/Rust environment)
- **git**: Git configuration
- **nvim**: Neovim configuration
- **Brewfile**: Homebrew package list for reproducible setup
- **scripts**: Bootstrap, snapshot, and verification workflows
- **state/**: Generated machine snapshots (tool versions, package state, extensions)
- **.githooks/**: Versioned git hooks for commit-time checks

## Privacy defaults

- Repo-tracked `git/gitconfig` does not contain personal identity values.
- Personal Git identity lives in `~/.gitconfig.local` (created from `git/gitconfig.local.example` during install).
- Update `~/.gitconfig.local` with your real name/email on each machine.

## Quick start

Clone the repo and run bootstrap:

```bash
git clone https://github.com/brianfakhoury/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
scripts/bootstrap.sh --install-homebrew
```

If Homebrew is already installed:

```bash
scripts/bootstrap.sh
```

## Core workflows

Install dotfiles only:

```bash
./install.sh
```

Preview installer actions without writing files:

```bash
./install.sh --dry-run
```

Verify current setup:

```bash
scripts/verify.sh
```

Enable git hooks manually (if needed):

```bash
scripts/setup-git-hooks.sh
```

Capture machine state:

```bash
scripts/snapshot.sh
```

Runbook for full rebuild:

```bash
cat docs/REBUILD.md
```

## Safe apply flow

Preview changes first:

```bash
./install.sh --dry-run
```

Apply changes:

```bash
./install.sh
```

Validate symlinks and startup:

```bash
scripts/verify.sh
```

## Structure

```text
dotfiles/
├── zsh/
│   ├── zshrc
│   ├── zshenv
│   └── zprofile
├── git/
│   └── gitconfig
├── nvim/
│   └── (neovim config files)
├── scripts/
│   ├── bootstrap.sh
│   ├── snapshot.sh
│   └── verify.sh
├── docs/
│   └── REBUILD.md
├── state/
│   └── (generated snapshots)
├── machine.local.example
├── profile
├── Brewfile
├── install.sh
└── README.md
```

## Notes

- `install.sh` creates timestamped backups before replacing existing non-symlink files.
- Use `./install.sh --dry-run` to preview every action before applying changes.
- Host-specific values belong in `~/.machine.local` (created from `machine.local.example` on first install).
- Git identity belongs in `~/.gitconfig.local` (created from `git/gitconfig.local.example`).
- `scripts/bootstrap.sh` enables versioned git hooks (`core.hooksPath=.githooks`) for commit-time verification.
- Symlinks allow changes to sync automatically: edit files in repo, changes apply immediately.
- Private keys and secrets are intentionally excluded.
- To update: `git pull` in the dotfiles directory.
