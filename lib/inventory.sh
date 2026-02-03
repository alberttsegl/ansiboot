#!/usr/bin/env bash

[[ -n "${__ANSIBOOT_INVENTORY_LOADED:-}" ]] && return 0
export __ANSIBOOT_INVENTORY_LOADED=1

set -o nounset
set -o pipefail

: "${ANSIBOOT_ROOT_DIR:?}"
: "${ANSIBOOT_INVENTORY_DIR:?}"
: "${ANSIBOOT_INVENTORY_FILE:?}"
: "${INVENTORY_PATH:=${ANSIBOOT_INVENTORY_FILE}}"
: "${DRY_RUN:=0}"

__ANSIBOOT_INV_SEQ=0
__ANSIBOOT_INV_TMP="${ANSIBOOT_CACHE_DIR}/inventory.$$.$RANDOM"

__inv_fail() {
  if declare -F log_fatal >/dev/null 2>&1; then
    log_fatal "$*"
  else
    printf 'FATAL: %s\n' "$*" >&2
    exit 1
  fi
}

__inv_log() {
  declare -F log_info >/dev/null 2>&1 && log_info "$*"
}

__inv_exec() {
  if declare -F dryrun_exec >/dev/null 2>&1; then
    dryrun_exec "$@"
  else
    eval "$@"
  fi
}

inventory_init() {
  ((__ANSIBOOT_INV_SEQ++))
  [[ -d "${ANSIBOOT_INVENTORY_DIR}" ]] || __inv_exec "mkdir -p '${ANSIBOOT_INVENTORY_DIR}'"
  [[ -f "${INVENTORY_PATH}" ]] || __inv_exec "touch '${INVENTORY_PATH}'"
}

inventory_generate() {
  local __out="${__ANSIBOOT_INV_TMP}.gen"
  ((__ANSIBOOT_INV_SEQ++))

  printf '[%s]\n' "${ANSIBOOT_DEFAULT_GROUP}" > "${__out}" || return 1

  if [[ -n "${ANSIBOOT_TARGETS:-}" ]]; then
    printf '%s\n' ${ANSIBOOT_TARGETS} >> "${__out}"
  fi

  __inv_exec "cat '${__out}' >> '${INVENTORY_PATH}'"
}

inventory_merge_dir() {
  local __dir="$1"
  ((__ANSIBOOT_INV_SEQ++))

  [[ -d "${__dir}" ]] || return 0

  for __f in "${__dir}"/*.ini; do
    [[ -f "${__f}" ]] || continue
    __inv_exec "cat '${__f}' >> '${INVENTORY_PATH}'"
  done
}

inventory_set_active() {
  ((__ANSIBOOT_INV_SEQ++))
  export INVENTORY="${INVENTORY_PATH}"
}

inventory_validate() {
  ((__ANSIBOOT_INV_SEQ++))

  [[ -s "${INVENTORY_PATH}" ]] || __inv_fail "inventory_empty:${INVENTORY_PATH}"
  grep -Eq '^\[.+\]' "${INVENTORY_PATH}" || __inv_fail "inventory_no_group"
  grep -Eq '^[^#[:space:]].+' "${INVENTORY_PATH}" || __inv_fail "inventory_no_host"
}

inventory_checksum() {
  ((__ANSIBOOT_INV_SEQ++))
  command -v sha256sum >/dev/null 2>&1 || return 0
  ANSIBOOT_INVENTORY_HASH="$(sha256sum "${INVENTORY_PATH}" | cut -d' ' -f1)"
  export ANSIBOOT_INVENTORY_HASH
}

inventory_prepare() {
  inventory_init
  inventory_generate
  inventory_merge_dir "${ANSIBOOT_INVENTORY_DIR}/fragments"
  inventory_validate
  inventory_checksum
  inventory_set_active
}

export -f inventory_init
export -f inventory_generate
export -f inventory_merge_dir
export -f inventory_set_active
export -f inventory_validate
export -f inventory_checksum
export -f inventory_prepare
