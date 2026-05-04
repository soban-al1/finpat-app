#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

echo "Running secret scan on tracked files..."
python3 - <<'PY'
import pathlib
import re
import subprocess
import sys

root = pathlib.Path.cwd()

ignored_suffixes = (
    ".env",
    ".env.example",
    ".env.prod.json",
    ".env.prod.json.example",
    "package-lock.json",
    "pubspec.lock",
)

patterns = [
    re.compile(
        r"SUPABASE_SERVICE_ROLE_KEY\s*[:=]\s*[\"']?[A-Za-z0-9._-]{20,}",
        re.IGNORECASE,
    ),
    re.compile(r"sk_live_[A-Za-z0-9]{16,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"AIza[0-9A-Za-z\-_]{35}"),
    re.compile(r"-----BEGIN (RSA|EC|OPENSSH|PRIVATE) KEY-----"),
    re.compile(r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"),
]

res = subprocess.run(
    ["git", "ls-files"],
    check=True,
    capture_output=True,
    text=True,
)
files = [line.strip() for line in res.stdout.splitlines() if line.strip()]

hits = []
for rel in files:
    if rel.endswith(ignored_suffixes):
        continue
    path = root / rel
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        continue
    for idx, line in enumerate(text.splitlines(), start=1):
        for rx in patterns:
            if rx.search(line):
                hits.append((rel, idx, line.strip()))
                break

if hits:
    print("Potential secret detected. Push blocked.")
    for rel, idx, line in hits[:20]:
        print(f"{rel}:{idx}: {line[:200]}")
    if len(hits) > 20:
        print(f"... and {len(hits) - 20} more matches")
    sys.exit(1)

print("Secret scan passed.")
PY
