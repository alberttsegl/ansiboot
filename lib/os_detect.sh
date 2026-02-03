#!/usr/bin/env bash

[[ -n "${__ANSIBOOT_OS_DETECT_LOADED:-}" ]] && return 0
export __ANSIBOOT_OS_DETECT_LOADED=1

set -o nounset
set -o pipefail

ANSIBOOT_OS_NAME=""
ANSIBOOT_OS_ID=""
ANSIBOOT_OS_VERSION=""
ANSIBOOT_OS_VERSION_ID=""
ANSIBOOT_OS_FAMILY=""
ANSIBOOT_OS_LIKE=""
ANSIBOOT_OS_ARCH="$(uname -m 2>/dev/null || echo unknown)"
ANSIBOOT_OS_KERNEL="$(uname -s 2>/dev/null || echo unknown)"

__ansiboot__os_from_release() {
  local __f="$1"
  [[ -r "${__f}" ]] || return 1
  while IFS='=' read -r __k __v; do
    __v="${__v%\"}"
    __v="${__v#\"}"
    case "${__k}" in
      NAME) ANSIBOOT_OS_NAME="${__v}" ;;
      ID) ANSIBOOT_OS_ID="${__v}" ;;
      VERSION) ANSIBOOT_OS_VERSION="${__v}" ;;
      VERSION_ID) ANSIBOOT_OS_VERSION_ID="${__v}" ;;
      ID_LIKE) ANSIBOOT_OS_LIKE="${__v}" ;;
    esac
  done < "${__f}"
  return 0
}

__ansiboot__normalize_family() {
  case "${ANSIBOOT_OS_ID}" in
    ubuntu|debian|linuxmint|pop|elementary) ANSIBOOT_OS_FAMILY="debian" ;;
    rhel|centos|rocky|almalinux|fedora) ANSIBOOT_OS_FAMILY="rhel" ;;
    arch|manjaro|endeavouros) ANSIBOOT_OS_FAMILY="arch" ;;
    opensuse*|sles) ANSIBOOT_OS_FAMILY="suse" ;;
    alpine) ANSIBOOT_OS_FAMILY="alpine" ;;
    *) ANSIBOOT_OS_FAMILY="unknown" ;;
  esac
}

__ansiboot__fallback_detect() {
  if command -v lsb_release >/dev/null 2>&1; then
    ANSIBOOT_OS_NAME="$(lsb_release -ds 2>/dev/null | tr -d '"')"
    ANSIBOOT_OS_ID="$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    ANSIBOOT_OS_VERSION_ID="$(lsb_release -rs 2>/dev/null)"
  fi
}

if [[ -r /etc/os-release ]]; then
  __ansiboot__os_from_release /etc/os-release
elif [[ -r /usr/lib/os-release ]]; then
  __ansiboot__os_from_release /usr/lib/os-release
else
  __ansiboot__fallback_detect
fi

__ansiboot__normalize_family

ANSIBOOT_OS_CAN_INSTALL=0
case "${ANSIBOOT_OS_FAMILY}" in
  debian|rhel|arch|suse|alpine) ANSIBOOT_OS_CAN_INSTALL=1 ;;
esac

ANSIBOOT_OS_PACKAGE_MANAGER=""
case "${ANSIBOOT_OS_FAMILY}" in
  debian) ANSIBOOT_OS_PACKAGE_MANAGER="apt" ;;
  rhel) ANSIBOOT_OS_PACKAGE_MANAGER="dnf" ;;
  arch) ANSIBOOT_OS_PACKAGE_MANAGER="pacman" ;;
  suse) ANSIBOOT_OS_PACKAGE_MANAGER="zypper" ;;
  alpine) ANSIBOOT_OS_PACKAGE_MANAGER="apk" ;;
esac

ANSIBOOT_OS_FINGERPRINT="$(
  printf '%s\n' \
    "${ANSIBOOT_OS_ID}" \
    "${ANSIBOOT_OS_VERSION_ID}" \
    "${ANSIBOOT_OS_ARCH}" \
    "${ANSIBOOT_OS_KERNEL}" \
  | tr '\n' ':' | sed 's/:$//'
)"

export ANSIBOOT_OS_NAME
export ANSIBOOT_OS_ID
export ANSIBOOT_OS_VERSION
export ANSIBOOT_OS_VERSION_ID
export ANSIBOOT_OS_LIKE
export ANSIBOOT_OS_FAMILY
export ANSIBOOT_OS_ARCH
export ANSIBOOT_OS_KERNEL
export ANSIBOOT_OS_CAN_INSTALL
export ANSIBOOT_OS_PACKAGE_MANAGER
export ANSIBOOT_OS_FINGERPRINT
