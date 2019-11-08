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

get_timer(){
    echo $(date +%s)
}

# $1: start timer
elapsed_time(){
    echo $(echo $1 $(get_timer) | awk '{ printf "%0.2f",($2-$1)/60 }')
}

show_elapsed_time(){
    info "Time %s: %s minutes" "$1" "$(elapsed_time $2)"
}

prepare_dir(){
    [[ ! -d $1 ]] && mkdir -p $1
}

get_osname(){
    . /usr/lib/os-release
    echo "${NAME}"
}

# orig_argv=("$0" "$@")
check_root() {
    local keepenv=$1

    (( EUID == 0 )) && return
    if type -P sudo >/dev/null; then
        exec sudo --preserve-env=$keepenv -- "${orig_argv[@]}"
    else
        exec su root -c "$(printf ' %q' "${orig_argv[@]}")"
    fi
}
