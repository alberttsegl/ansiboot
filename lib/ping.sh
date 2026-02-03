#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
ANSIBLE_CFG="$BASE_DIR/ansible.cfg"

source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/inventory.sh"
source "$BASE_DIR/lib/validator.sh"

[[ -f "$ANSIBLE_CFG" ]] || { log_fatal "ansible.cfg missing"; exit 1; }

HOSTS=()
mapfile -t HOSTS < <(load_inventory)

[[ "${#HOSTS[@]}" -gt 0 ]] || { log_fatal "inventory empty"; exit 1; }

export ANSIBLE_CONFIG="$ANSIBLE_CFG"

FAILED=0

for host in "${HOSTS[@]}"; do
    validate_host "$host" || { log_error "invalid host $host"; FAILED=1; continue; }

    if ansible "$host" -m ping -o >/dev/null 2>&1; then
        log_info "reachable $host"
    else
        log_error "unreachable $host"
        FAILED=1
    fi
done

[[ "$FAILED" -eq 0 ]] || { log_fatal "connectivity check failed"; exit 1; }

log_success "all hosts reachable"
