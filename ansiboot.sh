#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

SELF="${BASH_SOURCE[0]}"
ROOT="$(cd "$(dirname "$SELF")" && pwd)"
CFG="$ROOT/config"
LIB="$ROOT/lib"
SCR="$ROOT/scripts"
INV="$ROOT/inventory"
LOG="$ROOT/logs"
TMP="$ROOT/tmp"
RUN="$ROOT/.runtime"

mkdir -p "$LOG" "$TMP" "$RUN" "$LOG/history"

SESSION_TS="$(date +%Y%m%d-%H%M%S)"
SESSION_ID="$SESSION_TS-$$"
LOCK="$RUN/ansiboot.lock"

exec 9>"$LOCK" || exit 1
flock -n 9 || { echo "ansiboot already running"; exit 1; }

ACTIVE_LOG="$LOG/ansiboot.log"
[[ -f "$ACTIVE_LOG" ]] && mv "$ACTIVE_LOG" "$LOG/history/ansiboot_$(date +%F).log"
touch "$ACTIVE_LOG"
chmod 600 "$ACTIVE_LOG"

export ANSIBOOT_ROOT="$ROOT"
export ANSIBOOT_SESSION="$SESSION_ID"

source "$CFG/defaults.env"
[[ -f "$CFG/ansiboot.conf" ]] && source "$CFG/ansiboot.conf"

source "$LIB/logger.sh"
source "$LIB/dryrun.sh"
source "$LIB/validator.sh"
source "$LIB/os_detect.sh"
source "$LIB/inventory.sh"

export ANSIBLE_CONFIG="$CFG/ansible.cfg"

log_info "ansiboot start session=$SESSION_ID pid=$$"
log_info "config dry_run=${DRY_RUN:-false} verbose=${VERBOSE:-false}"

validate_bash
validate_os
validate_structure
validate_dependencies

STATE_FILE="$RUN/state.$SESSION_ID"
touch "$STATE_FILE"
chmod 600 "$STATE_FILE"

ARGS=("$@")
CMD="${ARGS[0]:-}"
SUB="${ARGS[1]:-}"

shift || true

cleanup() {
    rm -rf "$TMP"/*
    rm -f "$STATE_FILE"
    log_info "cleanup done session=$SESSION_ID"
}
trap cleanup EXIT INT TERM

guard_inventory() {
    [[ -d "$INV" ]] || { log_fatal "inventory missing"; exit 1; }
    [[ -d "$INV/inventory.d" ]] || { log_fatal "inventory fragments missing"; exit 1; }
}

guard_ansible_cfg() {
    [[ -f "$CFG/ansible.cfg" ]] || { log_fatal "ansible.cfg missing"; exit 1; }
}

dispatch_init() {
    log_info "dispatch init"
    "$SCR/self-check.sh"
    "$LIB/install_ansible.sh"
    guard_inventory
    "$LIB/inventory.sh" generate
    guard_ansible_cfg
    "$LIB/ssh_setup.sh"
    "$LIB/ping.sh"
}

dispatch_inventory() {
    log_info "dispatch inventory action=$SUB"
    guard_inventory
    case "$SUB" in
        generate)
            "$LIB/inventory.sh" generate
            ;;
        validate)
            "$LIB/inventory.sh" validate
            ;;
        list)
            "$LIB/inventory.sh" list
            ;;
        show)
            "$LIB/inventory.sh" show
            ;;
        *)
            log_fatal "invalid inventory action"
            exit 1
            ;;
    esac
}

dispatch_ssh() {
    log_info "dispatch ssh action=$SUB"
    case "$SUB" in
        setup)
            "$LIB/ssh_setup.sh"
            ;;
        *)
            log_fatal "invalid ssh action"
            exit 1
            ;;
    esac
}

dispatch_ping() {
    log_info "dispatch ping"
    guard_inventory
    guard_ansible_cfg
    "$LIB/ping.sh"
}

dispatch_adhoc() {
    log_info "dispatch adhoc args=${ARGS[*]}"
    guard_inventory
    guard_ansible_cfg
    "$LIB/adhoc.sh" "${ARGS[@]:1}"
}

dispatch_self_check() {
    log_info "dispatch self-check"
    "$SCR/self-check.sh"
}

dispatch_uninstall() {
    log_info "dispatch uninstall"
    "$SCR/uninstall.sh" "${ARGS[@]:1}"
}

dispatch_help() {
    echo "ansiboot <command>"
    echo "commands:"
    echo "  init"
    echo "  inventory generate|validate|list|show"
    echo "  ssh setup"
    echo "  ping"
    echo "  adhoc <ansible-args>"
    echo "  self-check"
    echo "  uninstall"
}

case "$CMD" in
    init)
        dispatch_init
        ;;
    inventory)
        dispatch_inventory
        ;;
    ssh)
        dispatch_ssh
        ;;
    ping)
        dispatch_ping
        ;;
    adhoc)
        dispatch_adhoc
        ;;
    self-check)
        dispatch_self_check
        ;;
    uninstall)
        dispatch_uninstall
        ;;
    help|"")
        dispatch_help
        ;;
    *)
        log_fatal "unknown command $CMD"
        exit 1
        ;;
esac

log_success "ansiboot exit session=$SESSION_ID"
