#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
CONF_FILE="$BASE_DIR/config/ansiboot.conf"
ENV_FILE="$BASE_DIR/defaults.env"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/ssh_setup_$(date +%F_%H-%M-%S).log"

mkdir -p "$LOG_DIR"

exec 3>&1 4>&2
exec > >(tee -a "$LOG_FILE" >&3) 2> >(tee -a "$LOG_FILE" >&4)

[[ -f "$CONF_FILE" ]] || { echo "missing ansiboot.conf"; exit 1; }
[[ -f "$ENV_FILE" ]] || { echo "missing defaults.env"; exit 1; }

source "$CONF_FILE"
source "$ENV_FILE"

: "${ANSIBLE_USER:?}"
: "${SSH_KEY_NAME:?}"
: "${SSH_KEY_BITS:?}"
: "${SSH_PORT:?}"
: "${DRY_RUN:?}"
: "${SSH_TIMEOUT:?}"

KEY_PATH="$HOME/.ssh/$SSH_KEY_NAME"
PUB_KEY_PATH="$KEY_PATH.pub"

run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] $*"
    else
        "$@"
    fi
}

validate_host() {
    [[ -n "$1" ]] || return 1
    [[ "$1" =~ ^[a-zA-Z0-9._-]+$ ]]
}

generate_key() {
    [[ -f "$KEY_PATH" ]] && return 0
    run ssh-keygen -t rsa -b "$SSH_KEY_BITS" -f "$KEY_PATH" -N "" -q
}

copy_key() {
    local host="$1"
    run ssh-copy-id -i "$PUB_KEY_PATH" -p "$SSH_PORT" -o ConnectTimeout="$SSH_TIMEOUT" "$ANSIBLE_USER@$host"
}

test_ssh() {
    local host="$1"
    run ssh -p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout="$SSH_TIMEOUT" "$ANSIBLE_USER@$host" "echo ok" >/dev/null
}

load_hosts() {
    mapfile -t HOSTS < <(grep -E '^[a-zA-Z0-9._-]+$' "$BASE_DIR/inventory/hosts")
}

load_hosts

[[ "${#HOSTS[@]}" -gt 0 ]] || { echo "no hosts found"; exit 1; }

for host in "${HOSTS[@]}"; do
    validate_host "$host" || { echo "invalid host: $host"; continue; }
    "$BASE_DIR/lib/validator.sh" "$host" || { echo "validator failed: $host"; continue; }
    "$BASE_DIR/lib/ping.sh" "$host" || { echo "unreachable: $host"; continue; }
    generate_key
    copy_key "$host"
    test_ssh "$host"
    echo "ssh ready: $host"
done

echo "ssh setup completed"
