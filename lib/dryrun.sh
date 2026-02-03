#!/usr/bin/env bash

[[ -n "${__ANSIBOOT_DRYRUN_LOADED:-}" ]] && return 0
export __ANSIBOOT_DRYRUN_LOADED=1

set -o nounset
set -o pipefail

: "${DRY_RUN:=0}"
: "${ANSIBOOT_FAIL_FAST:=1}"
: "${ANSIBOOT_SILENT:=0}"

__ANSIBOOT_EXEC_SEQ=0

__ansiboot__normalize_cmd() {
  local __in="$*"
  printf '%s' "${__in//$'\n'/ }"
}

__ansiboot__emit() {
  local __mode="$1"
  shift
  local __cmd="$*"

  if declare -F log_info >/dev/null 2>&1; then
    log_info "[${__mode}] ${__cmd}"
  else
    printf '[%s] %s\n' "${__mode}" "${__cmd}" >&2
  fi
}

__ansiboot__fail() {
  local __msg="$*"
  if declare -F log_fatal >/dev/null 2>&1; then
    log_fatal "${__msg}"
  else
    printf 'FATAL: %s\n' "${__msg}" >&2
    exit 1
  fi
}

dryrun_exec() {
  local __raw="$*"
  local __cmd
  __cmd="$(__ansiboot__normalize_cmd "${__raw}")"
  ((__ANSIBOOT_EXEC_SEQ++))

  if (( DRY_RUN == 1 )); then
    __ansiboot__emit "dry-run:${__ANSIBOOT_EXEC_SEQ}" "${__cmd}"
    return 0
  fi

  __ansiboot__emit "exec:${__ANSIBOOT_EXEC_SEQ}" "${__cmd}"

  eval "${__raw}"
  local __rc=$?

  if (( __rc != 0 && ANSIBOOT_FAIL_FAST == 1 )); then
    __ansiboot__fail "command failed (${__rc}): ${__cmd}"
  fi

  return "${__rc}"
}

dryrun_pipe() {
  local __lhs="$1"
  local __rhs="$2"
  ((__ANSIBOOT_EXEC_SEQ++))

  local __repr
  __repr="$(__ansiboot__normalize_cmd "${__lhs} | ${__rhs}")"

  if (( DRY_RUN == 1 )); then
    __ansiboot__emit "dry-run:${__ANSIBOOT_EXEC_SEQ}" "${__repr}"
    return 0
  fi

  __ansiboot__emit "exec:${__ANSIBOOT_EXEC_SEQ}" "${__repr}"

  eval "${__lhs} | ${__rhs}"
  local __rc=$?

  if (( __rc != 0 && ANSIBOOT_FAIL_FAST == 1 )); then
    __ansiboot__fail "pipeline failed (${__rc}): ${__repr}"
  fi

  return "${__rc}"
}

dryrun_capture() {
  local __var="$1"
  shift
  local __cmd="$*"
  ((__ANSIBOOT_EXEC_SEQ++))

  if (( DRY_RUN == 1 )); then
    __ansiboot__emit "dry-run:${__ANSIBOOT_EXEC_SEQ}" "${__cmd}"
    printf -v "${__var}" '%s' ""
    return 0
  fi

  __ansiboot__emit "exec:${__ANSIBOOT_EXEC_SEQ}" "${__cmd}"

  local __out
  __out="$(eval "${__cmd}")"
  local __rc=$?

  printf -v "${__var}" '%s' "${__out}"

  if (( __rc != 0 && ANSIBOOT_FAIL_FAST == 1 )); then
    __ansiboot__fail "capture failed (${__rc}): ${__cmd}"
  fi

  return "${__rc}"
}

dryrun_assert_disabled() {
  local __why="$*"
  if (( DRY_RUN == 1 )); then
    __ansiboot__emit "blocked" "${__why}"
    return 1
  fi
  return 0
}

export -f dryrun_exec
export -f dryrun_pipe
export -f dryrun_capture
export -f dryrun_assert_disabled
