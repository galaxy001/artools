#!/hint/bash

#{{{ message

#set +u +o posix

# shellcheck disable=1091
. /usr/share/makepkg/util.sh

export LANG=C

shopt -s extglob

if [[ -t 2 && "$TERM" != dumb ]]; then
    colorize
else
    declare -gr ALL_OFF='' BOLD='' BLUE='' GREEN='' RED='' YELLOW=''
fi

info() {
    local mesg=$1; shift
    # shellcheck disable=2059
    printf "${YELLOW} -->${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

stat_busy() {
    local mesg=$1; shift
    # shellcheck disable=2059
    printf "${GREEN}==>${ALL_OFF}${BOLD} ${mesg}...${ALL_OFF}" "$@" >&2
}

stat_done() {
    # shellcheck disable=2059
    printf "${BOLD}done${ALL_OFF}\n" >&2
}

lock_close() {
	local fd=$1
	exec {fd}>&-
}

lock() {
    if ! [[ "/dev/fd/$1" -ef "$2" ]]; then
        mkdir -p -- "$(dirname -- "$2")"
        eval "exec $1>"'"$2"'
    fi
    if ! flock -n "$1"; then
        stat_busy "$3"
        flock "$1"
        stat_done
    fi
}

slock() {
    if ! [[ "/dev/fd/$1" -ef "$2" ]]; then
        mkdir -p -- "$(dirname -- "$2")"
        eval "exec $1>"'"$2"'
    fi
    if ! flock -sn "$1"; then
        stat_busy "$3"
        flock -s "$1"
        stat_done
    fi
}

_setup_workdir=false
setup_workdir() {
    [[ -z ${WORKDIR:-} ]] && WORKDIR=$(mktemp -d --tmpdir "${0##*/}.XXXXXXXXXX")
    _setup_workdir=true
    trap 'trap_abort' INT QUIT TERM HUP
    trap 'trap_exit' EXIT
}

trap_abort() {
    trap - EXIT INT QUIT TERM HUP
    abort
}

trap_exit() {
    local r=$?
    trap - EXIT INT QUIT TERM HUP
    cleanup $r
}

cleanup() {
    if [[ -n ${WORKDIR:-} ]] && $_setup_workdir; then
        rm -rf "$WORKDIR"
    fi
    exit "${1:-0}"
}

abort() {
    error 'Aborting...'
    cleanup 255
}

die() {
    (( $# )) && error "$@"
    cleanup 255
}

#}}}
