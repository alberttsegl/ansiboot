#!/usr/bin/env bash

[[ -n "${__ANSIBOOT_LOGGER_LOADED:-}" ]] && return 0
export __ANSIBOOT_LOGGER_LOADED=1

set -o nounset
set -o pipefail

: "${ANSIBOOT_LOG_LEVEL:=INFO}"
: "${ANSIBOOT_LOG_FILE:=/dev/null}"
: "${ANSIBOOT_LOG_STDERR:=1}"
: "${ANSIBOOT_LOG_COLOR:=0}"
: "${ANSIBOOT_LOG_TIMESTAMP_FORMAT:=%Y-%m-%d %H:%M:%S}"
: "${ANSIBOOT_SILENT:=0}"
: "${DRY_RUN:=0}"

declare -A __ANSIBOOT_LOG_LEVELS
__ANSIBOOT_LOG_LEVELS=(
  [TRACE]=0
  [DEBUG]=1
  [INFO]=2
  [WARN]=3
  [ERROR]=4
  [FATAL]=5
)

__ANSIBOOT_LOG_LEVEL_NUM="${__ANSIBOOT_LOG_LEVELS[${ANSIBOOT_LOG_LEVEL}]:-2}"

__ANSIBOOT_COLOR_TRACE=$'\033[90m'
__ANSIBOOT_COLOR_DEBUG=$'\033[36m'
__ANSIBOOT_COLOR_INFO=$'\033[32m'
__ANSIBOOT_COLOR_WARN=$'\033[33m'
__ANSIBOOT_COLOR_ERROR=$'\033[31m'
__ANSIBOOT_COLOR_FATAL=$'\033[1;31m'
__ANSIBOOT_COLOR_RESET=$'\033[0m'

__ansiboot__log_emit() {
  local __lvl="$1"
  shift
  local __msg="$*"
  local __lvl_num="${__ANSIBOOT_LOG_LEVELS[$__lvl]:-99}"

  (( __lvl_num < __ANSIBOOT_LOG_LEVEL_NUM )) && return 0
  (( ANSIBOOT_SILENT == 1 )) && return 0

  local __ts
  __ts="$(date +"${ANSIBOOT_LOG_TIMESTAMP_FORMAT}" 2>/dev/null || echo epoch)"

  local __prefix="[$__ts][$__lvl]"

  local __color=""
  if (( ANSIBOOT_LOG_COLOR == 1 )); then
    case "$__lvl" in
      TRACE) __color="$__ANSIBOOT_COLOR_TRACE" ;;
      DEBUG) __color="$__ANSIBOOT_COLOR_DEBUG" ;;
      INFO)  __color="$__ANSIBOOT_COLOR_INFO" ;;
      WARN)  __color="$__ANSIBOOT_COLOR_WARN" ;;
      ERROR) __color="$__ANSIBOOT_COLOR_ERROR" ;;
      FATAL) __color="$__ANSIBOOT_COLOR_FATAL" ;;
    esac
  fi

  local __line="${__prefix} ${__msg}"

  if (( ANSIBOOT_LOG_STDERR == 1 )); then
    if [[ -t 2 ]]; then
      printf "%s%s%s\n" "${__color}" "${__line}" "${__ANSIBOOT_COLOR_RESET}" >&2
    else
      printf "%s\n" "${__line}" >&2
    fi
  fi

  if [[ -n "${ANSIBOOT_LOG_FILE}" ]]; then
    printf "%s\n" "${__line}" >> "${ANSIBOOT_LOG_FILE}" 2>/dev/null || true
  fi
}

log_trace() { __ansiboot__log_emit TRACE "$*"; }
log_debug() { __ansiboot__log_emit DEBUG "$*"; }
log_info()  { __ansiboot__log_emit INFO  "$*"; }
log_warn()  { __ansiboot__log_emit WARN  "$*"; }
log_error() { __ansiboot__log_emit ERROR "$*"; }
log_fatal() {
  __ansiboot__log_emit FATAL "$*"
  exit 1
}

log_exec() {
  local __cmd="$*"
  if (( DRY_RUN == 1 )); then
    log_info "[dry-run] ${__cmd}"
    return 0
  fi
  log_debug "[exec] ${__cmd}"
  eval "${__cmd}"
}

log_kv() {
  local __k="$1"
  local __v="$2"
  log_debug "${__k}=${__v}"
}

export -f log_trace
export -f log_debug
export -f log_info
export -f log_warn
export -f log_error
export -f log_fatal
export -f log_exec
export -f log_kv
