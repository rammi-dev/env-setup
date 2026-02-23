# functions/kubernetes.sh
# Complex shell functions — sourced by .bashrc.local

# listcrd: list all CRD instances in current namespace, or all namespaces with -A
listcrd() {
    local ALL_NS=false
    local NS_ARG

    if [[ "${1:-}" == "-A" || "${1:-}" == "--all-namespaces" ]]; then
        ALL_NS=true
    fi

    if [[ "$ALL_NS" == false ]]; then
        local NS
        NS=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
        NS="${NS:-default}"
        NS_ARG="-n $NS"
    else
        NS_ARG="--all-namespaces"
    fi

    local -a crds
    mapfile -t crds < <(kubectl get crds -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n')

    if [[ ${#crds[@]} -eq 0 ]]; then
        echo "No CRDs found in the cluster." >&2
        return 1
    fi

    local found=false
    for crd in "${crds[@]}"; do
        local instances
        if [[ "$ALL_NS" == true ]]; then
            instances=$(kubectl get "$crd" $NS_ARG \
                --no-headers \
                -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name' \
                2>/dev/null | paste -sd "," -)
        else
            instances=$(kubectl get "$crd" $NS_ARG \
                --no-headers \
                -o custom-columns='NAME:.metadata.name' \
                2>/dev/null | paste -sd "," -)
        fi
        if [[ -n "$instances" ]]; then
            printf "%-60s %s\n" "$crd:" "$instances"
            found=true
        fi
    done

    [[ "$found" == false ]] && echo "No CRD instances found${ALL_NS:+ across all namespaces}."
}
