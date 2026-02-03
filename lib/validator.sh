#!/usr/bin/env bash

[[ -n "${__ANSIBOOT_VALIDATOR_LOADED:-}" ]] && return 0
export __ANSIBOOT_VALIDATOR_LOADED=1

set -o nounset
set -o pipefail

: "${ANSIBOOT_ROOT_DIR:?}"
: "${ANSIBOOT_CONFIG_DIR:?}"
: "${ANSIBOOT_CACHE_DIR:?}"
: "${ANSIBOOT_LOG_DIR:?}"
: "${ANSIBOOT_INVENTORY_FILE:?}"
: "${BIN_ANSIBLE:?}"
: "${BIN_SSH:?}"
: "${SSH_USER:?}"
: "${SSH_PORT:?}"

__ANSIBOOT_VALIDATION_ERRORS=0

__ansiboot_vfail() {
  ((__ANSIBOOT_VALIDATION_ERRORS++))
  if declare -F log_error >/dev/null 2>&1; then
    log_error "$*"
  else
    printf 'ERROR: %s\n' "$*" >&2
  fi
}

__ansiboot_vfatal() {
  if declare -F log_fatal >/dev/null 2>&1; then
    log_fatal "$*"
  else
    printf 'FATAL: %s\n' "$*" >&2
    exit 1
  fi
}

validator_require_bin() {
  local __b
  for __b in "$@"; do
    command -v "${__b}" >/dev/null 2>&1 || __ansiboot_vfail "binary_missing:${__b}"
  done
}

validator_require_file() {
  local __f
  for __f in "$@"; do
    [[ -f "${__f}" ]] || __ansiboot_vfail "file_missing:${__f}"
  done
}

validator_require_dir() {
  local __d
  for __d in "$@"; do
    [[ -d "${__d}" ]] || __ansiboot_vfail "dir_missing:${__d}"
  done
}

validator_require_writable() {
  local __p
  for __p in "$@"; do
    [[ -w "${__p}" ]] || __ansiboot_vfail "not_writable:${__p}"
  done
}

validator_require_readable() {
  local __p
  for __p in "$@"; do
    [[ -r "${__p}" ]] || __ansiboot_vfail "not_readable:${__p}"
  done
}

validator_inventory_sanity() {
  [[ -s "${ANSIBOOT_INVENTORY_FILE}" ]] || __ansiboot_vfail "inventory_empty:${ANSIBOOT_INVENTORY_FILE}"
  grep -Eq '^\[.+\]' "${ANSIBOOT_INVENTORY_FILE}" || __ansiboot_vfail "inventory_no_group:${ANSIBOOT_INVENTORY_FILE}"
  grep -Eq '^[^#[:space:]].+' "${ANSIBOOT_INVENTORY_FILE}" || __ansiboot_vfail "inventory_no_hosts:${ANSIBOOT_INVENTORY_FILE}"
}

validator_port_sanity() {
  [[ "${SSH_PORT}" =~ ^[0-9]+$ ]] || __ansiboot_vfail "ssh_port_invalid:${SSH_PORT}"
  (( SSH_PORT > 0 && SSH_PORT < 65536 )) || __ansiboot_vfail "ssh_port_range:${SSH_PORT}"
}

validator_user_sanity() {
  [[ -n "${SSH_USER}" ]] || __ansiboot_vfail "ssh_user_empty"
}

validator_ansible_ping() {
  (( DRY_RUN == 1 )) && return 0
  command -v "${BIN_ANSIBLE}" >/dev/null 2>&1 || return 0
  "${BIN_ANSIBLE}" --version >/dev/null 2>&1 || __ansiboot_vfail "ansible_unusable"
}

validator_finalize() {
  (( __ANSIBOOT_VALIDATION_ERRORS == 0 )) || __ansiboot_vfatal "validation_failed:${__ANSIBOOT_VALIDATION_ERRORS}"
  return 0
}

validator_require_bin \
  "${BIN_ANSIBLE}" \
  "${BIN_SSH}" \
  awk sed grep cut tr date

validator_require_dir \
  "${ANSIBOOT_ROOT_DIR}" \
  "${ANSIBOOT_CONFIG_DIR}" \
  "${ANSIBOOT_CACHE_DIR}" \
  "${ANSIBOOT_LOG_DIR}"

validator_require_file \
  "${ANSIBOOT_INVENTORY_FILE}"

validator_require_readable \
  "${ANSIBOOT_INVENTORY_FILE}"

validator_require_writable \
  "${ANSIBOOT_LOG_DIR}" \
  "${ANSIBOOT_CACHE_DIR}"

validator_inventory_sanity
validator_port_sanity
validator_user_sanity
validator_ansible_ping

validator_finalize

export -f validator_require_bin
export -f validator_require_file
export -f validator_require_dir
export -f validator_require_writable
export -f validator_require_readable
export -f validator_inventory_sanity
export -f validator_port_sanity
export -f validator_user_sanity
export -f validator_finalize
