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

shopt -s extglob

get_compliant_name(){
    local gitname="$1"
    case "$gitname" in
        *+) gitname=${gitname//+/plus}
    esac
    echo "$gitname"
}

set_arch_repos(){
    local x="$1" y="$2" z="$3"
    ARCH_REPOS=(core extra community multilib)

    $x && ARCH_REPOS+=(testing community-testing multilib-testing)
    $y && ARCH_REPOS+=(staging community-staging multilib-staging)
    $z && ARCH_REPOS+=(gnome-unstable kde-unstable)
}

find_repo(){
    local pkg="$1" repo= pkgarch="${2:-${CARCH}}"
    for r in ${ARCH_REPOS[@]};do
        [[ -f $pkg/repos/$r-$pkgarch/PKGBUILD ]] && repo=repos/"$r-$pkgarch"
        [[ -f $pkg/repos/$r-any/PKGBUILD ]] && repo=repos/"$r"-any
        [[ -f $pkg/$pkgarch/$r/PKGBUILD ]] && repo="$pkgarch/$r"
    done
    echo $repo
}

find_pkg(){
    local searchdir="$1" pkg="$2"
    local result=$(find "$searchdir" -mindepth 2 -maxdepth 2 -type d -name "$pkg")
    echo "$result"
}

find_cached_pkgfile() {
    local searchdirs=("$PKGDEST" "$PWD") results=()
    local pkg="$1"
    for dir in "${searchdirs[@]}"; do
        [[ -d "$dir" ]] || continue
        [[ -e "$dir/$pkg" ]] && results+=("$dir/$pkg")
    done
    case ${#results[*]} in
        0)
            return 1
        ;;
        1)
            printf '%s\n' "${results[0]}"
            return 0
        ;;
        *)
            error 'Multiple packages found:'
            printf '\t%s\n' "${results[@]}" >&2
            return 1
        ;;
    esac
}
