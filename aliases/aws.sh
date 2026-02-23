# aliases/aws.sh
# AWS CLI shortcuts

alias awsid='aws sts get-caller-identity'
alias awsregion='aws configure get region'
alias awsprofile='echo $AWS_PROFILE'

# Switch AWS profile: awsp <profile-name>
awsp() {
    if [[ -z "${1:-}" ]]; then
        aws configure list-profiles
        return
    fi
    export AWS_PROFILE="$1"
    echo "AWS_PROFILE set to: $AWS_PROFILE"
    aws sts get-caller-identity 2>/dev/null && echo "✓ Auth OK" || echo "⚠ Auth failed — check credentials"
}

# List S3 buckets
alias s3ls='aws s3 ls'

# Tail CloudWatch logs: cwlogs <log-group> [minutes-back]
cwlogs() {
    local group="${1:?Usage: cwlogs <log-group> [minutes-back]}"
    local minutes="${2:-5}"
    local since
    since=$(date -d "-${minutes} minutes" +%s000)
    aws logs filter-log-events --log-group-name "$group" --start-time "$since" \
        --output text --query 'events[*].message'
}
