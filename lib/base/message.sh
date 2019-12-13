#!/bin/bash
#
# Copyright (C) 2018-19 artoo@artixlinux.org
# Copyright (C) 2018 Artix Linux Developers
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# export LC_MESSAGES=C
export LANG=C

if [[ -t 2 && "$TERM" != dumb ]]; then
    colorize
else
    declare -gr ALL_OFF='' BOLD='' BLUE='' GREEN='' RED='' YELLOW=''
fi

info() {
    local mesg=$1; shift
    printf "${YELLOW} -->${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

stat_busy() {
    local mesg=$1; shift
    printf "${GREEN}==>${ALL_OFF}${BOLD} ${mesg}...${ALL_OFF}" "$@" >&2
}

stat_done() {
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
    if ! flock -n $1; then
        stat_busy "$3"
        flock $1
        stat_done
    fi
}

slock() {
    if ! [[ "/dev/fd/$1" -ef "$2" ]]; then
        mkdir -p -- "$(dirname -- "$2")"
        eval "exec $1>"'"$2"'
    fi
    if ! flock -sn $1; then
        stat_busy "$3"
        flock -s $1
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

msg_table_header(){
    local mesg=$1; shift
    printf "${BLUE} ${mesg} ${ALL_OFF}\n" "$@" >&2
}

msg_row_downgrade(){
    local mesg=$1; shift
    printf "${YELLOW} ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg_row_notify(){
    local mesg=$1; shift
    printf "${GREEN} ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg_row(){
    local mesg=$1; shift
#     printf "${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
    printf "${WHITE} ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg_row_upgrade(){
    local mesg=$1; shift
    printf "${RED} ${mesg} ${ALL_OFF}\n" "$@" >&2
}
