#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

umask 077

SELF="${BASH_SOURCE[0]}"
BASE_DIR="$(cd "$(dirname "$SELF")"/.. && pwd)"
CFG_DIR="$BASE_DIR/config"
LIB_DIR="$BASE_DIR/lib"

source "$CFG_DIR/defaults.env"
[[ -f "$CFG_DIR/ansiboot.conf" ]] && source "$CFG_DIR/ansiboot.conf"

source "$LIB_DIR/logger.sh"
source "$LIB_DIR/dryrun.sh"
source "$LIB_DIR/validator.sh"
source "$LIB_DIR/inventory.sh"

ANSIBLE_CFG="$CFG_DIR/ansible.cfg"
export ANSIBLE_CONFIG="$ANSIBLE_CFG"

[[ -x "$(command -v ansible)" ]] || { log_fatal "ansible not found"; exit 1; }
[[ -f "$ANSIBLE_CFG" ]] || { log_fatal "ansible.cfg missing"; exit 1; }

validate_inventory || { log_fatal "inventory invalid"; exit 1; }

CMD_ARGS=("$@")
[[ "${#CMD_ARGS[@]}" -gt 0 ]] || { log_fatal "no adhoc arguments"; exit 1; }

TARGETS=()
mapfile -t TARGETS < <(load_inventory)

[[ "${#TARGETS[@]}" -gt 0 ]] || { log_fatal "inventory empty"; exit 1; }

SAFE_ARGS=()
for arg in "${CMD_ARGS[@]}"; do
    [[ "$arg" =~ [\;\&\|\`\<\>] ]] && { log_fatal "unsafe character detected"; exit 1; }
    SAFE_ARGS+=("$arg")
done

ANSIBLE_BIN="$(command -v ansible)"
EXECUTION_MATRIX=()

for host in "${TARGETS[@]}"; do
    validate_host "$host" || { log_error "skip invalid host $host"; continue; }
    EXECUTION_MATRIX+=("$ANSIBLE_BIN" "$host")
done

[[ "${#EXECUTION_MATRIX[@]}" -gt 0 ]] || { log_fatal "no valid execution target"; exit 1; }

RESULT_CODE=0

for ((i=0; i<${#EXECUTION_MATRIX[@]}; i+=2)); do
    BIN="${EXECUTION_MATRIX[i]}"
    HOST="${EXECUTION_MATRIX[i+1]}"

    FULL_CMD=("$BIN" "$HOST" "${SAFE_ARGS[@]}")

    log_info "adhoc target=$HOST args=${SAFE_ARGS[*]}"

    if run_cmd "${FULL_CMD[@]}"; then
        log_success "adhoc success $HOST"
    else
        log_error "adhoc failed $HOST"
        RESULT_CODE=1
    fi
done

[[ "$RESULT_CODE" -eq 0 ]] || { log_fatal "adhoc execution failed"; exit 1; }

log_success "adhoc execution completed"
