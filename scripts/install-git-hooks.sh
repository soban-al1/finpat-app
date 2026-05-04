#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

chmod +x scripts/scan-secrets.sh scripts/install-git-hooks.sh .githooks/pre-push
git config core.hooksPath .githooks

echo "Git hooks installed."
echo "pre-push now runs scripts/scan-secrets.sh"
