#!/usr/bin/env bash
# install.sh — idempotent tool installer for env-setup
# Run once on a new machine: bash ~/env-setup/install.sh
# Safe to re-run: skips tools that are already installed.
#
# Installs (to ~/.local/bin, no sudo except jq/yq/vim):
#   uv, kubectx, kubens, mvn, jq, yq, aws-cli, gemini-cli, vim, vim-plug, listcrd

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# Load version pins (overridable via env)
# shellcheck source=config/versions.env
source "$REPO_DIR/config/versions.env"

# ─── Helpers ─────────────────────────────────────────────────────────────────
info()    { echo "[install] $*"; }
skip()    { echo "[install] ✓ $1 already installed — skipping"; }
section() { echo; echo "── $* ──────────────────────────────────────────────"; }

_os()   { uname -s | tr '[:upper:]' '[:lower:]'; }
_arch() {
    local a; a=$(uname -m)
    [[ "$a" == "x86_64" ]]  && echo "amd64" && return
    [[ "$a" == "aarch64" ]] && echo "arm64" && return
    echo "$a"
}

# ─── uv ──────────────────────────────────────────────────────────────────────
section "uv (Python package manager)"
if ! command -v uv &>/dev/null; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$LOCAL_BIN:$PATH"
    info "uv installed: $(uv --version)"
else
    skip "uv ($(uv --version))"
fi

# ─── kubectx + kubens ────────────────────────────────────────────────────────
section "kubectx + kubens v${KUBECTX_VERSION}"
if ! command -v kubectx &>/dev/null; then
    info "Installing kubectx + kubens..."
    TMP=$(mktemp -d)
    TARBALL="kubectx_v${KUBECTX_VERSION}_$(_os)_$(_arch).tar.gz"
    curl -fsSL \
        "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/${TARBALL}" \
        -o "$TMP/$TARBALL"
    tar -xzf "$TMP/$TARBALL" -C "$TMP"
    install -m 0755 "$TMP/kubectx" "$LOCAL_BIN/kubectx"
    install -m 0755 "$TMP/kubens"  "$LOCAL_BIN/kubens"
    rm -rf "$TMP"
    info "kubectx + kubens installed to $LOCAL_BIN"
else
    skip "kubectx + kubens"
fi

# ─── Maven ───────────────────────────────────────────────────────────────────
section "Maven v${MAVEN_VERSION}"
if ! command -v mvn &>/dev/null; then
    info "Installing Maven..."
    TMP=$(mktemp -d)
    MVN_DIR="apache-maven-${MAVEN_VERSION}"
    curl -fsSL \
        "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/${MVN_DIR}-bin.tar.gz" \
        -o "$TMP/maven.tar.gz"
    tar -xzf "$TMP/maven.tar.gz" -C "$HOME/.local"
    ln -sf "$HOME/.local/${MVN_DIR}/bin/mvn" "$LOCAL_BIN/mvn"
    rm -rf "$TMP"
    info "mvn installed: $(mvn --version | head -1)"
else
    skip "mvn ($(mvn --version | head -1))"
fi

# ─── jq ──────────────────────────────────────────────────────────────────────
section "jq"
if ! command -v jq &>/dev/null; then
    info "Installing jq (requires sudo)..."
    sudo apt-get install -y -q jq
    info "jq installed: $(jq --version)"
else
    skip "jq ($(jq --version))"
fi

# ─── yq ──────────────────────────────────────────────────────────────────────
section "yq v${YQ_VERSION}"
if ! command -v yq &>/dev/null; then
    info "Installing yq (requires sudo)..."
    sudo wget -qO /usr/local/bin/yq \
        "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
    sudo chmod +x /usr/local/bin/yq
    info "yq installed: $(yq --version)"
else
    skip "yq ($(yq --version))"
fi

# ─── Vim ─────────────────────────────────────────────────────────────────────
section "Vim"
if ! command -v vim &>/dev/null; then
    info "Installing vim (requires sudo)..."
    sudo apt-get install -y -q vim
else
    skip "vim ($(vim --version | head -1))"
fi

# Symlink vimrc
if [[ ! -f "$HOME/.vimrc" ]]; then
    ln -s "$REPO_DIR/vim/vimrc" "$HOME/.vimrc"
    info "Symlinked vim/vimrc → ~/.vimrc"
elif [[ "$(readlink -f "$HOME/.vimrc")" == "$REPO_DIR/vim/vimrc" ]]; then
    skip "~/.vimrc symlink"
else
    info "Warning: ~/.vimrc already exists and is not managed by this repo. Skipping symlink."
fi

# vim-plug
section "vim-plug"
PLUG_PATH="$HOME/.vim/autoload/plug.vim"
if [[ ! -f "$PLUG_PATH" ]]; then
    info "Installing vim-plug..."
    curl -fLo "$PLUG_PATH" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    info "vim-plug installed. Run :PlugInstall inside vim to install plugins."
else
    skip "vim-plug"
fi

# ─── AWS CLI v2 ──────────────────────────────────────────────────────────────
section "AWS CLI v2"
if ! command -v aws &>/dev/null; then
    info "Installing AWS CLI v2..."
    TMP=$(mktemp -d)
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$TMP/awscliv2.zip"
    unzip -q "$TMP/awscliv2.zip" -d "$TMP"
    # Install to ~/.local/aws, symlink binary — no sudo needed
    "$TMP/aws/install" --install-dir "$HOME/.local/aws-cli" --bin-dir "$LOCAL_BIN" --update
    rm -rf "$TMP"
    info "aws installed: $(aws --version)"
else
    skip "aws ($(aws --version 2>&1 | head -1))"
fi

# AWS SDK for Python (boto3) — installed as a uv tool
section "boto3 (AWS Python SDK)"
if command -v uv &>/dev/null; then
    if ! uv tool list 2>/dev/null | grep -q boto3; then
        info "Installing boto3 via uv..."
        # Add boto3 to a shared uv environment accessible globally
        uv tool install boto3 2>/dev/null || info "boto3 is a library — add to your project with: uv add boto3"
    else
        skip "boto3"
    fi
else
    info "uv not found — skipping boto3 (run install.sh again after uv is installed)"
fi

# ─── Gemini CLI ───────────────────────────────────────────────────────────────
section "Gemini CLI"

# Gemini CLI requires Node.js >= 20
_ensure_node20() {
    local node_major=0
    command -v node &>/dev/null && node_major=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)
    if [[ "$node_major" -lt 20 ]]; then
        info "Node.js ${node_major:-not found} < 20 — installing Node.js 20 LTS (requires sudo)..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y -q nodejs
        info "Node.js installed: $(node --version)"
    fi
}

if ! command -v gemini &>/dev/null; then
    _ensure_node20
    info "Installing Gemini CLI via npm (userspace prefix)..."
    # Install to ~/.local to avoid needing sudo for global npm packages
    npm install -g @google/gemini-cli --prefix "$HOME/.local" 2>&1 | grep -v "^npm warn EBADENGINE" || true
    # npm --prefix puts binary in ~/.local/bin automatically
    if command -v gemini &>/dev/null; then
        info "gemini installed: $(gemini --version 2>/dev/null || echo 'ok')"
    else
        info "gemini binary installed to $HOME/.local/bin — ensure it is in PATH"
    fi
else
    skip "gemini ($(gemini --version 2>/dev/null || echo 'installed'))"
fi


# ─── gcloud CLI ─────────────────────────────────────────────────────────────────
section "gcloud CLI"
if ! command -v gcloud &>/dev/null; then
    info "Installing Google Cloud SDK..."
    curl -fsSL https://sdk.cloud.google.com | bash -s -- \
        --disable-prompts \
        --install-dir="$HOME"
    # Add to PATH for this session
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
    # Install kubectl component via gcloud
    gcloud components install kubectl --quiet 2>/dev/null || true
    info "gcloud installed: $(gcloud --version | head -1)"
else
    GCLOUD_VER=$(gcloud --version 2>/dev/null | head -1)
    skip "gcloud ($GCLOUD_VER)"
fi

# ─── listcrd ─────────────────────────────────────────────────────────────────
section "listcrd"
LISTCRD_SRC="$REPO_DIR/scripts/listcrd"
LISTCRD_DEST="$LOCAL_BIN/listcrd"
if [[ ! -f "$LISTCRD_DEST" ]] || [[ "$(readlink -f "$LISTCRD_DEST")" != "$LISTCRD_SRC" ]]; then
    install -m 0755 "$LISTCRD_SRC" "$LISTCRD_DEST"
    info "listcrd installed to $LISTCRD_DEST"
else
    skip "listcrd"
fi

# ─── VS Code ─────────────────────────────────────────────────────────────────
section "VS Code"
if command -v code &>/dev/null; then
    # Extensions
    bash "$REPO_DIR/vscode/install-extensions.sh"

    # Symlink settings.json
    VSCODE_DIR="$HOME/.config/Code/User"
    VSCODE_SETTINGS="$VSCODE_DIR/settings.json"
    mkdir -p "$VSCODE_DIR"
    if [[ ! -e "$VSCODE_SETTINGS" ]]; then
        ln -s "$REPO_DIR/vscode/settings.json" "$VSCODE_SETTINGS"
        info "Symlinked vscode/settings.json → $VSCODE_SETTINGS"
    elif [[ "$(readlink -f "$VSCODE_SETTINGS" 2>/dev/null)" == "$REPO_DIR/vscode/settings.json" ]]; then
        skip "vscode/settings.json symlink"
    else
        info "Warning: $VSCODE_SETTINGS already exists and is not managed by this repo."
        info "Backup and replace manually:  cp $VSCODE_SETTINGS ${VSCODE_SETTINGS}.bak && ln -sf $REPO_DIR/vscode/settings.json $VSCODE_SETTINGS"
    fi
else
    info "VS Code 'code' not in PATH — skipping."
    info "On WSL: open VS Code from Windows once; it registers 'code' automatically."
fi

# ─── ~/.bashrc hook ──────────────────────────────────────────────────────────
section "~/.bashrc hook"
HOOK="[ -f $REPO_DIR/.bashrc.local ] && source $REPO_DIR/.bashrc.local"
if ! grep -qF '.bashrc.local' "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# env-setup" >> "$HOME/.bashrc"
    echo "$HOOK" >> "$HOME/.bashrc"
    info "Added source hook to ~/.bashrc"
else
    skip "~/.bashrc hook (already present)"
fi

# ─── Done ────────────────────────────────────────────────────────────────────
echo
echo "╔══════════════════════════════════════════════════╗"
echo "║  env-setup install complete!                     ║"
echo "║                                                  ║"
echo "║  Next steps:                                     ║"
echo "║   1. source ~/.bashrc                            ║"
echo "║   2. vim → :PlugInstall                          ║"
echo "║   3. aws configure      (AWS credentials)        ║"
echo "║   4. gemini auth        (Gemini API key)         ║"
echo "║   5. Open VS Code → verify extensions loaded     ║"
echo "╚══════════════════════════════════════════════════╝"
