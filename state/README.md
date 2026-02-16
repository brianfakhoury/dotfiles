# state/

Generated machine snapshot artifacts. These are intentionally committed so
current machine state is visible and reproducible over time.

- `brew-versions.txt`: installed Homebrew formula/cask versions
- `brew-taps.txt`: active Homebrew taps
- `vscode-extensions.txt`: installed VS Code extensions
- `ai-tools.txt`: key CLI tool versions (agent/codex/etc.)
- `git-global-config.txt`: global git config snapshot with sensitive values redacted

Refresh with:

```bash
scripts/snapshot.sh
```
