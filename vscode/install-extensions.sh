#!/usr/bin/env bash
# vscode/install-extensions.sh
# Installs VS Code extensions from extensions.txt
# Safe to re-run — skips already-installed extensions.
# Usage: bash ~/env-setup/vscode/install-extensions.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSIONS_FILE="$SCRIPT_DIR/extensions.txt"

if ! command -v code &>/dev/null; then
    echo "[vscode] 'code' not found in PATH."
    echo "[vscode] On WSL: open VS Code from Windows first — it registers 'code' in PATH automatically."
    exit 1
fi

# Get currently installed extensions (lowercase for comparison)
INSTALLED=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

installed_count=0
skipped_count=0

while IFS= read -r line; do
    # Strip comments and blank lines
    ext="${line%%#*}"          # remove inline comment
    ext="${ext// /}"           # strip spaces
    [[ -z "$ext" ]] && continue

    ext_lower="${ext,,}"

    if echo "$INSTALLED" | grep -qi "^${ext_lower}$"; then
        echo "[vscode] ✓ $ext already installed"
        (( skipped_count++ )) || true
    else
        echo "[vscode] Installing $ext ..."
        code --install-extension "$ext" --force 2>/dev/null && \
            echo "[vscode] ✓ $ext installed" || \
            echo "[vscode] ✗ Failed to install $ext (check extension ID)"
        (( installed_count++ )) || true
    fi
done < "$EXTENSIONS_FILE"

echo
echo "[vscode] Done. Installed: $installed_count | Skipped (already present): $skipped_count"
