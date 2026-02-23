# env-setup

> Portable dev environment — clone once, run `install.sh` on any new machine.

## Quick Start

```bash
git clone https://github.com/yourusername/env-setup.git ~/env-setup
bash ~/env-setup/install.sh
source ~/.bashrc
```

## What Gets Installed

| Tool | Purpose | Method |
|------|---------|--------|
| `uv` | Python package manager | curl installer |
| `kubectx` + `kubens` | kubectl context/namespace switcher | GitHub binary |
| `mvn` | Maven build tool | Apache binary tarball |
| `jq` | JSON processor | apt |
| `yq` | YAML processor | GitHub binary |
| `vim` | Editor | apt |
| `vim-plug` | Vim plugin manager | curl |
| `listcrd` | List CRD instances | this repo |

All binaries go to `~/.local/bin` (no sudo except `jq`, `yq`, `vim`).

## Repo Structure

```
env-setup/
├── install.sh              # One-time: install all tools
├── update.sh               # Periodic: check + update tools
├── .bashrc.local           # Sourced by ~/.bashrc: aliases, PATH, completions
├── aliases/
│   └── kubernetes.sh       # k, kg, kd, kl, kx, kn
├── functions/
│   └── kubernetes.sh       # listcrd function
├── scripts/
│   └── listcrd             # Standalone CRD lister (on PATH)
├── vim/
│   └── vimrc               # Symlinked to ~/.vimrc
├── config/
│   └── versions.env        # Pinned tool versions
└── README.md
```

## Shell Aliases

| Alias | Expands to |
|-------|-----------|
| `k`   | `kubectl` |
| `kg`  | `kubectl get` |
| `kd`  | `kubectl describe` |
| `kl`  | `kubectl logs` |
| `kx`  | `kubectx` |
| `kn`  | `kubens` |

## `listcrd`

List all CRD instances in the cluster:

```bash
listcrd          # current namespace (from kubeconfig)
listcrd -A       # all namespaces
```

Output is column-aligned:

```
cert-manager.io/v1/certificates:           default/my-cert,staging/api-cert
networking.istio.io/v1alpha3/gateways:     ingress-gateway
```

## Updating Tools

```bash
./update.sh           # interactive: prompts per outdated tool
./update.sh --yes     # auto-update all
./update.sh --check   # report versions only, no changes
```

Version pins in `config/versions.env` are updated automatically after an upgrade.

## Vim

Config in `vim/vimrc`, symlinked to `~/.vimrc` by `install.sh`.

**Colorscheme**: [onedark](https://github.com/joshdick/onedark.vim) — sharp, high contrast, no harsh blues.

**Plugins** (install with `:PlugInstall` inside vim):
- `coc.nvim` — LSP autocomplete for Python, Java, SQL
- `vim-python/python-syntax` — enhanced Python highlighting
- `pearofducks/ansible-vim` — YAML/Ansible highlighting
- `vim-javacomplete2` — Java completion
- `lightline.vim` — status bar
- `NERDTree` — file tree
- `fzf.vim` — fuzzy file/text search

**Per-language settings**:
| Language | Indent | Extra |
|----------|--------|-------|
| Python | 4 spaces | `<leader>f` formats with black |
| YAML | 2 spaces | fold by indent |
| Java | 4 spaces | omnifunc completion |
| SQL | 2 spaces | `<leader>u` uppercases keywords |

## Pin / Override Versions

```bash
# Temporarily override a version:
KUBECTX_VERSION=0.9.6 bash install.sh

# Or edit config/versions.env permanently:
vim config/versions.env
```

## Adding a New Machine

```bash
git clone https://github.com/yourusername/env-setup.git ~/env-setup
bash ~/env-setup/install.sh
# Open vim and run: :PlugInstall
```
