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

declare -A REPOS=(
    [core]=system
    [extra]=world
    [community]=galaxy
    [multilib]=lib32
    [testing]=gremlins
    [staging]=goblins
    [community-testing]=galaxy-gremlins
    [community-staging]=galaxy-goblins
    [multilib-testing]=lib32-gremlins
    [multilib-staging]=lib32-goblins
    [kde-unstable]=kde-wobble
    [gnome-unstable]=gnome-wobble
)

ARCH_REPOS=(
    core
    extra
    community
    multilib
)

get_compliant_name(){
    local gitname="$1"
    case $gitname in
        *+) gitname=${gitname//+/plus}
    esac
    echo $gitname
}

get_group_packages(){
    local pkglist="${SYSCONFDIR}/pkglist.d/$1.list"

    local _space="s| ||g" _clean=':a;N;$!ba;s/\n/ /g' _com_rm="s|#.*||g"

    local pkgs=($(sed "$_com_rm" "$pkglist" | sed "$_space" | sed "$_clean"))

    local cases=
    for p in ${pkgs[@]};do
        cases=${cases:-}${cases:+|}${p}
    done
    echo $cases
}

get_group(){
    local pkg="$1" fallback="${2##*/}" tree=
    eval "case $pkg in
        $(get_group_packages kernel)) tree=packages-kernel ;;
        $(get_group_packages python)) tree=packages-python ;;
        $(get_group_packages perl)) tree=packages-perl ;;
        $(get_group_packages ruby)) tree=packages-ruby ;;
        $(get_group_packages openrc)) tree=packages-openrc ;;
        $(get_group_packages runit)) tree=packages-runit ;;
        $(get_group_packages s6)) tree=packages-s6 ;;
        $(get_group_packages media)) tree=packages-media ;;
        $(get_group_packages xorg)) tree=packages-xorg ;;
        $(get_group_packages qt5)) tree=packages-qt5 ;;
        $(get_group_packages gtk)) tree=packages-gtk ;;
        $(get_group_packages java)) tree=packages-java ;;
        $(get_group_packages haskell)) tree=packages-haskell ;;
        $(get_group_packages devel)) tree=packages-devel ;;
        $(get_group_packages lxqt)) tree=packages-lxqt ;;
        $(get_group_packages cinnamon)) tree=packages-cinnamon ;;
        $(get_group_packages kde)) tree=packages-kde ;;
        $(get_group_packages gnome)) tree=packages-gnome ;;
        $(get_group_packages mate)) tree=packages-mate ;;
        $(get_group_packages xfce)) tree=packages-xfce ;;
        *) tree=$fallback ;;
    esac"
    echo $tree
}

set_arch_repos(){
    local x="$1" y="$2" z="$3"

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
