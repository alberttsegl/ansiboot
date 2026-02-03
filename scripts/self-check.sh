#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

umask 077

SELF="${BASH_SOURCE[0]}"
BASE_DIR="$(cd "$(dirname "$SELF")"/.. && pwd)"
CFG_DIR="$BASE_DIR/config"
LIB_DIR="$BASE_DIR/lib"
INV_DIR="$BASE_DIR/inventory"

REQUIRED_BASH_MAJOR=4

[[ -n "${BASH_VERSINFO[0]:-}" ]] || { echo "invalid bash runtime"; exit 1; }
(( BASH_VERSINFO[0] >= REQUIRED_BASH_MAJOR )) || { echo "bash version unsupported"; exit 1; }

[[ -d "$CFG_DIR" ]] || { echo "config directory missing"; exit 1; }
[[ -d "$LIB_DIR" ]] || { echo "lib directory missing"; exit 1; }
[[ -d "$INV_DIR" ]] || { echo "inventory directory missing"; exit 1; }

[[ -f "$CFG_DIR/defaults.env" ]] || { echo "defaults.env missing"; exit 1; }
[[ -f "$CFG_DIR/ansible.cfg" ]] || { echo "ansible.cfg missing"; exit 1; }

source "$CFG_DIR/defaults.env"
[[ -f "$CFG_DIR/ansiboot.conf" ]] && source "$CFG_DIR/ansiboot.conf"

source "$LIB_DIR/validator.sh"

BINARIES=(bash ssh ssh-keygen awk sed grep cut sort uniq tr)

for bin in "${BINARIES[@]}"; do
    command -v "$bin" >/dev/null 2>&1 || { echo "missing binary $bin"; exit 1; }
done

if command -v ansible >/dev/null 2>&1; then
    :
else
    echo "ansible not installed"
fi

OS_NAME="$(uname -s)"
[[ "$OS_NAME" == "Linux" ]] || { echo "unsupported os $OS_NAME"; exit 1; }

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    [[ -n "${ID:-}" ]] || { echo "os id undefined"; exit 1; }
else
    echo "os-release missing"
    exit 1
fi

[[ -r "$CFG_DIR" ]] || { echo "config not readable"; exit 1; }
[[ -w "$CFG_DIR" ]] || { echo "config not writable"; exit 1; }
[[ -x "$LIB_DIR" ]] || { echo "lib not accessible"; exit 1; }

[[ -f "$INV_DIR/inventory.ini" ]] || { echo "inventory.ini missing"; exit 1; }
[[ -d "$INV_DIR/inventory.d" ]] || { echo "inventory.d missing"; exit 1; }

INV_FILES=("$INV_DIR/inventory.d"/*.ini)
[[ "${#INV_FILES[@]}" -gt 0 ]] || { echo "no inventory fragments"; exit 1; }

for f in "${INV_FILES[@]}"; do
    [[ -s "$f" ]] || { echo "empty inventory fragment $f"; exit 1; }
    validate_inventory_file "$f" || { echo "invalid inventory $f"; exit 1; }
done

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

touch "$TMP_DIR/.perm_test" || { echo "filesystem permission failure"; exit 1; }
rm -f "$TMP_DIR/.perm_test"

if [[ -n "${ANSIBOOT_LOG_DIR:-}" ]]; then
    mkdir -p "$ANSIBOOT_LOG_DIR" || { echo "log dir not writable"; exit 1; }
fi

echo "self-check passed"
