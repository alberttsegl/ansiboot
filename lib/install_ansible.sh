#!/usr/bin/env bash

[[ -n "${__ANSIBOOT_INSTALL_LOADED:-}" ]] && return 0
export __ANSIBOOT_INSTALL_LOADED=1

set -o nounset
set -o pipefail

: "${ANSIBOOT_OS_FAMILY:?}"
: "${ANSIBOOT_OS_PACKAGE_MANAGER:?}"
: "${BIN_ANSIBLE:=ansible}"
: "${DRY_RUN:=0}"

__ansiboot_install_state=0

__ansiboot_install_fail() {
  if declare -F log_fatal >/dev/null 2>&1; then
    log_fatal "$*"
  else
    printf 'FATAL: %s\n' "$*" >&2
    exit 1
  fi
}

__ansiboot_install_ok() {
  if declare -F log_info >/dev/null 2>&1; then
    log_info "$*"
  fi
}

__ansiboot_install_cmd() {
  if declare -F dryrun_exec >/dev/null 2>&1; then
    dryrun_exec "$@"
  else
    eval "$@"
  fi
}

command -v "${BIN_ANSIBLE}" >/dev/null 2>&1 && {
  __ansiboot_install_ok "ansible_present"
  return 0
}

case "${ANSIBOOT_OS_FAMILY}" in
  debian)
    __ansiboot_install_cmd "apt-get update -y"
    __ansiboot_install_cmd "apt-get install -y software-properties-common"
    __ansiboot_install_cmd "apt-get install -y ansible"
    ;;
  rhel)
    __ansiboot_install_cmd "${ANSIBOOT_OS_PACKAGE_MANAGER} makecache -y"
    __ansiboot_install_cmd "${ANSIBOOT_OS_PACKAGE_MANAGER} install -y epel-release"
    __ansiboot_install_cmd "${ANSIBOOT_OS_PACKAGE_MANAGER} install -y ansible"
    ;;
  arch)
    __ansiboot_install_cmd "pacman -Sy --noconfirm ansible"
    ;;
  suse)
    __ansiboot_install_cmd "zypper --non-interactive refresh"
    __ansiboot_install_cmd "zypper --non-interactive install ansible"
    ;;
  alpine)
    __ansiboot_install_cmd "apk update"
    __ansiboot_install_cmd "apk add ansible"
    ;;
  *)
    __ansiboot_install_fail "unsupported_os_family:${ANSIBOOT_OS_FAMILY}"
    ;;
esac

if (( DRY_RUN == 0 )); then
  command -v "${BIN_ANSIBLE}" >/dev/null 2>&1 || __ansiboot_install_fail "ansible_not_found_after_install"
  "${BIN_ANSIBLE}" --version >/dev/null 2>&1 || __ansiboot_install_fail "ansible_unusable"
fi

__ansiboot_install_ok "ansible_ready"
