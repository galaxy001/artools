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
    case $gitname in
        *+) gitname=${gitname//+/plus}
    esac
    echo $gitname
}

set_arch_repos(){
    local x="$1" y="$2" z="$3"
    ARCH_REPOS=(core extra community multilib)

    $x && ARCH_REPOS+=(testing community-testing multilib-testing)
    $y && ARCH_REPOS+=(staging community-staging multilib-staging)
    $z && ARCH_REPOS+=(gnome-unstable kde-unstable)
}

find_repo(){
    local pkg="$1" repo=
    for r in ${ARCH_REPOS[@]};do
        [[ -f $pkg/repos/$r-${ARCH}/PKGBUILD ]] && repo=$r-${ARCH}
        [[ -f $pkg/repos/$r-any/PKGBUILD ]] && repo=$r-any
    done
    echo $repo
}

find_pkg(){
    local searchdir="$1" pkg="$2"
    local result=$(find $searchdir -mindepth 2 -maxdepth 2 -type d -name "$pkg")
    echo $result
}

pkgver_equal() {
    if [[ $1 = *-* && $2 = *-* ]]; then
        # if both versions have a pkgrel, then they must be an exact match
        [[ $1 = "$2" ]]
    else
        # otherwise, trim any pkgrel and compare the bare version.
        [[ ${1%%-*} = "${2%%-*}" ]]
    fi
}

find_cached_package() {
    local searchdirs=("$PKGDEST" "$PWD") results=()
    local targetname=$1 targetver=$2 targetarch=$3
    local dir pkg pkgbasename name ver rel arch r results

    for dir in "${searchdirs[@]}"; do
        [[ -d $dir ]] || continue

        for pkg in "$dir"/*.pkg.tar?(.!(sig|*.*)); do
            [[ -f $pkg ]] || continue

            # avoid adding duplicates of the same inode
            for r in "${results[@]}"; do
                [[ $r -ef $pkg ]] && continue 2
            done

            # split apart package filename into parts
            pkgbasename=${pkg##*/}
            pkgbasename=${pkgbasename%.pkg.tar*}

            arch=${pkgbasename##*-}
            pkgbasename=${pkgbasename%-"$arch"}

            rel=${pkgbasename##*-}
            pkgbasename=${pkgbasename%-"$rel"}

            ver=${pkgbasename##*-}
            name=${pkgbasename%-"$ver"}

            if [[ $targetname = "$name" && $targetarch = "$arch" ]] &&
                pkgver_equal "$targetver" "$ver-$rel"; then
                results+=("$pkg")
            fi
        done
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
