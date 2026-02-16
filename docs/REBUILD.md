# Rebuild Runbook

This is the shortest path to reproduce this machine setup on a fresh host.

## 1) Clone dotfiles

```bash
git clone https://github.com/brianfakhoury/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
```

## 2) Bootstrap

```bash
scripts/bootstrap.sh --install-homebrew
```

If Homebrew already exists, `scripts/bootstrap.sh` without flags is enough.

Optional preflight before writes:

```bash
./install.sh --dry-run
```

## 3) Add host-local overrides

Edit `~/.machine.local` and set machine-specific values (secrets, local paths, aliases).
Edit `~/.gitconfig.local` and set your machine-local Git identity values.

## 4) Verify setup

```bash
scripts/verify.sh
```

## 5) Enable git hooks

```bash
scripts/setup-git-hooks.sh
```

This enables the repo's versioned pre-commit hook (`.githooks/pre-commit`).

## 6) Capture current machine state

```bash
scripts/snapshot.sh
git add Brewfile state/
git commit -m "chore(dotfiles): refresh machine snapshot"
```

## Notes

- `install.sh` creates timestamped backups for existing files before linking.
- `install.sh --dry-run` prints exact link/backup/create actions without modifying files.
- `scripts/verify.sh --quick` runs static/local checks only.
- `scripts/snapshot.sh` is safe to run repeatedly; it rewrites generated state files.
