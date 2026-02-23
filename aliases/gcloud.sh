# aliases/gcloud.sh
# Google Cloud SDK shortcuts — sourced by .bashrc.local

# ── Project / Account ────────────────────────────────────
alias gcp-whoami='gcloud auth list'
alias gcp-proj='gcloud config get-value project'
alias gcp-set-proj='gcloud config set project'

# Switch active gcloud config: gcfg <config-name>
gcfg() {
    if [[ -z "${1:-}" ]]; then
        gcloud config configurations list
        return
    fi
    gcloud config configurations activate "$1"
    echo "Active config: $1 | Project: $(gcloud config get-value project)"
}

# ── GKE ──────────────────────────────────────────────────
# Get kubeconfig for a GKE cluster: gke-auth <cluster> <zone/region>
gke-auth() {
    local cluster="${1:?Usage: gke-auth <cluster-name> <zone-or-region>}"
    local location="${2:?Usage: gke-auth <cluster-name> <zone-or-region>}"
    gcloud container clusters get-credentials "$cluster" --zone "$location"
    echo "kubeconfig updated for cluster: $cluster"
}

# ── Compute ───────────────────────────────────────────────
alias gcp-vms='gcloud compute instances list'
alias gcp-ssh='gcloud compute ssh'

# ── Completions ───────────────────────────────────────────
# gcloud ships its own completion — sourced here if SDK is present
_GCLOUD_SDK="$HOME/google-cloud-sdk"
if [[ -f "$_GCLOUD_SDK/completion.bash.inc" ]]; then
    source "$_GCLOUD_SDK/completion.bash.inc"
fi
