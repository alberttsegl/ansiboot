#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

umask 077

SELF="${BASH_SOURCE[0]}"
BASE_DIR="$(cd "$(dirname "$SELF")"/.. && pwd)"
CFG_DIR="$BASE_DIR/config"
LIB_DIR="$BASE_DIR/lib"
INV_DIR="$BASE_DIR/inventory"
LOG_DIR=""
TMP_DIRS=()
REMOVE_SSH_KEY=0

[[ -f "$CFG_DIR/defaults.env" ]] && source "$CFG_DIR/defaults.env"
[[ -f "$CFG_DIR/ansiboot.conf" ]] && source "$CFG_DIR/ansiboot.conf"

[[ -n "${ANSIBOOT_LOG_DIR:-}" ]] && LOG_DIR="$ANSIBOOT_LOG_DIR"
[[ -n "${ANSIBOOT_TMP_DIR:-}" ]] && TMP_DIRS+=("$ANSIBOOT_TMP_DIR")

for arg in "$@"; do
    case "$arg" in
        --with-ssh-key) REMOVE_SSH_KEY=1 ;;
        --force) ;;
        *) ;;
    esac
done

if [[ -n "$LOG_DIR" && -d "$LOG_DIR" ]]; then
    find "$LOG_DIR" -type f -name 'ansiboot*' -exec rm -f {} +
    rmdir "$LOG_DIR" 2>/dev/null || true
fi

for tdir in "${TMP_DIRS[@]}"; do
    [[ -d "$tdir" ]] && rm -rf "$tdir"
done

GEN_CFG="$CFG_DIR/ansible.cfg"
[[ -f "$GEN_CFG" ]] && rm -f "$GEN_CFG"

GEN_INV="$INV_DIR/inventory.ini"
[[ -f "$GEN_INV" ]] && rm -f "$GEN_INV"

RUNTIME_DIR="$BASE_DIR/.runtime"
[[ -d "$RUNTIME_DIR" ]] && rm -rf "$RUNTIME_DIR"

if [[ "$REMOVE_SSH_KEY" -eq 1 ]]; then
    SSH_KEY_PATH="${ANSIBOOT_SSH_KEY_PATH:-$HOME/.ssh/ansiboot}"
    [[ -f "$SSH_KEY_PATH" ]] && rm -f "$SSH_KEY_PATH"
    [[ -f "$SSH_KEY_PATH.pub" ]] && rm -f "$SSH_KEY_PATH.pub"
fi

CACHE_DIR="$BASE_DIR/.cache"
[[ -d "$CACHE_DIR" ]] && rm -rf "$CACHE_DIR"

find "$BASE_DIR" -type f -name '*.lock' -delete

echo "ansiboot uninstalled cleanly"
