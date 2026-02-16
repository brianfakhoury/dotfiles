#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -d "$REPO_ROOT/.git" ]; then
  echo "[hooks] not a git repository: $REPO_ROOT" >&2
  exit 1
fi

chmod +x "$REPO_ROOT/.githooks/pre-commit"
git -C "$REPO_ROOT" config --local core.hooksPath .githooks

echo "[hooks] configured core.hooksPath=.githooks"
echo "[hooks] pre-commit hook enabled"
