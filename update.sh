#!/usr/bin/env bash
# update.sh — check and update all managed tools
# Usage:
#   ./update.sh          # interactive: prompts per outdated tool
#   ./update.sh --yes    # auto-update all outdated tools
#   ./update.sh --check  # report only, no updates

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/config/versions.env"

AUTO_YES=false
CHECK_ONLY=false
for arg in "$@"; do
    [[ "$arg" == "--yes" ]]   && AUTO_YES=true
    [[ "$arg" == "--check" ]] && CHECK_ONLY=true
done

LOCAL_BIN="$HOME/.local/bin"

# ─── Helpers ─────────────────────────────────────────────────────────────────
info()    { echo "[update] $*"; }
ok()      { echo "[update] ✓ $*"; }
outdated(){ echo "[update] ↑ $*"; }

_confirm() {
    local msg="$1"
    if $AUTO_YES; then return 0; fi
    $CHECK_ONLY && return 1
    read -r -p "$msg [y/N] " ans
    [[ "${ans,,}" == "y" ]]
}

_github_latest() {
    # Usage: _github_latest owner/repo
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
        | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/' | head -1
}

_os()   { uname -s | tr '[:upper:]' '[:lower:]'; }
_arch() {
    local a; a=$(uname -m)
    [[ "$a" == "x86_64" ]]  && echo "amd64" && return
    [[ "$a" == "aarch64" ]] && echo "arm64" && return
    echo "$a"
}

# ─── uv ──────────────────────────────────────────────────────────────────────
echo "── uv ───────────────────────────────────────────────"
if command -v uv &>/dev/null; then
    INSTALLED="$(uv --version | awk '{print $2}')"
    LATEST="$(_github_latest astral-sh/uv)"
    if [[ "$INSTALLED" == "$LATEST" ]]; then
        ok "uv $INSTALLED is up to date"
    else
        outdated "uv $INSTALLED → $LATEST"
        if _confirm "Update uv?"; then
            curl -LsSf https://astral.sh/uv/install.sh | sh
            info "uv updated to $LATEST"
        fi
    fi
else
    info "uv not installed — run install.sh"
fi

# ─── kubectx + kubens ────────────────────────────────────────────────────────
echo "── kubectx + kubens ─────────────────────────────────"
if command -v kubectx &>/dev/null; then
    INSTALLED="$(kubectx --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    LATEST="$(_github_latest ahmetb/kubectx)"
    if [[ "$INSTALLED" == "$LATEST" ]]; then
        ok "kubectx $INSTALLED is up to date"
    else
        outdated "kubectx $INSTALLED → $LATEST"
        if _confirm "Update kubectx + kubens?"; then
            TMP=$(mktemp -d)
            TARBALL="kubectx_v${LATEST}_$(_os)_$(_arch).tar.gz"
            curl -fsSL \
                "https://github.com/ahmetb/kubectx/releases/download/v${LATEST}/${TARBALL}" \
                -o "$TMP/$TARBALL"
            tar -xzf "$TMP/$TARBALL" -C "$TMP"
            install -m 0755 "$TMP/kubectx" "$LOCAL_BIN/kubectx"
            install -m 0755 "$TMP/kubens"  "$LOCAL_BIN/kubens"
            rm -rf "$TMP"
            # Update pin in versions.env
            sed -i "s/^KUBECTX_VERSION=.*/KUBECTX_VERSION=${LATEST}/" "$REPO_DIR/config/versions.env"
            info "kubectx + kubens updated to $LATEST (versions.env updated)"
        fi
    fi
else
    info "kubectx not installed — run install.sh"
fi

# ─── yq ──────────────────────────────────────────────────────────────────────
echo "── yq ───────────────────────────────────────────────"
if command -v yq &>/dev/null; then
    INSTALLED="$(yq --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    LATEST="$(_github_latest mikefarah/yq)"
    if [[ "$INSTALLED" == "$LATEST" ]]; then
        ok "yq $INSTALLED is up to date"
    else
        outdated "yq $INSTALLED → $LATEST"
        if _confirm "Update yq? (requires sudo)"; then
            sudo wget -qO /usr/local/bin/yq \
                "https://github.com/mikefarah/yq/releases/download/v${LATEST}/yq_linux_amd64"
            sudo chmod +x /usr/local/bin/yq
            sed -i "s/^YQ_VERSION=.*/YQ_VERSION=${LATEST}/" "$REPO_DIR/config/versions.env"
            info "yq updated to $LATEST (versions.env updated)"
        fi
    fi
else
    info "yq not installed — run install.sh"
fi

# ─── Maven ───────────────────────────────────────────────────────────────────
echo "── Maven ────────────────────────────────────────────"
if command -v mvn &>/dev/null; then
    INSTALLED="$(mvn --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    LATEST="$(_github_latest apache/maven | head -1 || echo "$MAVEN_VERSION")"
    if [[ "$INSTALLED" == "$LATEST" ]]; then
        ok "mvn $INSTALLED is up to date"
    else
        outdated "mvn $INSTALLED → $MAVEN_VERSION (pinned in versions.env)"
        info "Maven is pinned. Edit MAVEN_VERSION in config/versions.env and re-run install.sh to upgrade."
    fi
else
    info "mvn not installed — run install.sh"
fi

# ─── jq ──────────────────────────────────────────────────────────────────────
echo "── jq ───────────────────────────────────────────────"
if command -v jq &>/dev/null; then
    INSTALLED="$(jq --version)"
    LATEST_APT="$(apt-cache policy jq 2>/dev/null | grep Candidate | awk '{print $2}')"
    if [[ -n "$LATEST_APT" && "$INSTALLED" == *"$LATEST_APT"* ]]; then
        ok "jq $INSTALLED is up to date"
    else
        outdated "jq $INSTALLED — apt candidate: ${LATEST_APT:-unknown}"
        if _confirm "Update jq via apt? (requires sudo)"; then
            sudo apt-get install -y -q jq
            info "jq updated"
        fi
    fi
else
    info "jq not installed — run install.sh"
fi

# ─── listcrd ─────────────────────────────────────────────────────────────────
echo "── listcrd ──────────────────────────────────────────"
LISTCRD_DEST="$LOCAL_BIN/listcrd"
LISTCRD_SRC="$REPO_DIR/scripts/listcrd"
if [[ -f "$LISTCRD_DEST" ]]; then
    if diff -q "$LISTCRD_SRC" "$LISTCRD_DEST" &>/dev/null; then
        ok "listcrd is up to date"
    else
        outdated "listcrd (repo version differs from installed)"
        if _confirm "Update listcrd?"; then
            install -m 0755 "$LISTCRD_SRC" "$LISTCRD_DEST"
            info "listcrd updated"
        fi
    fi
else
    info "listcrd not installed — run install.sh"
fi

echo "── gcloud ───────────────────────────────────────────"
if command -v gcloud &>/dev/null; then
    INSTALLED="$(gcloud --version 2>/dev/null | head -1)"
    outdated "gcloud uses its own updater"
    if _confirm "Update gcloud? (uses: gcloud components update)"; then
        gcloud components update --quiet
        info "gcloud updated: $(gcloud --version | head -1)"
    else
        ok "gcloud $INSTALLED (skipped)"
    fi
else
    info "gcloud not installed — run install.sh"
fi

# ─── VS Code extensions ───────────────────────────────────────────────────────
echo "── VS Code extensions ───────────────────────────────"
if command -v code &>/dev/null; then
    EXTENSIONS_FILE="$REPO_DIR/vscode/extensions.txt"
    INSTALLED_EXTS=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
    missing=0
    while IFS= read -r line; do
        ext="${line%%#*}"; ext="${ext// /}"
        [[ -z "$ext" ]] && continue
        if ! echo "$INSTALLED_EXTS" | grep -qi "^${ext,,}$"; then
            outdated "VS Code extension missing: $ext"
            (( missing++ )) || true
        fi
    done < "$EXTENSIONS_FILE"
    if [[ $missing -eq 0 ]]; then
        ok "All VS Code extensions installed"
    elif _confirm "Install $missing missing extension(s)?"; then
        bash "$REPO_DIR/vscode/install-extensions.sh"
    fi
else
    info "VS Code 'code' not in PATH — skipping"
fi

echo
echo "── Done ─────────────────────────────────────────────"
echo "Review config/versions.env to change pinned versions."
