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

get_compliant_name(){
    local gitname="$1"
    case $gitname in
        *+) gitname=${gitname//+/plus}
    esac
    echo $gitname
}

patch_pkg(){
    local pkg="$1"
    case $pkg in
        'glibc')
            sed -e 's|{locale,systemd/system,tmpfiles.d}|{locale,tmpfiles.d}|' \
                -e '/nscd.service/d' \
                -i $pkg/trunk/PKGBUILD
        ;;
        'tp_smapi'|'acpi_call'|'r8168'|'bbswitch'|'broadcom-wl')
            sed -e 's|-ARCH|-ARTIX|g' -i $pkg/trunk/PKGBUILD
        ;;
        'nvidia')
            sed -e 's|-ARCH|-ARTIX|g'  -e 's|for Arch kernel|for Artix kernel|g' \
                -e 's|for LTS Arch kernel|for LTS Artix kernel|g' \
                -i $pkg/trunk/PKGBUILD
        ;;
        'linux')
            sed -e 's|-ARCH|-ARTIX|g' -i $pkg/trunk/PKGBUILD
            sed -e 's|CONFIG_DEFAULT_HOSTNAME=.*|CONFIG_DEFAULT_HOSTNAME="artixlinux"|' \
                -e 's|CONFIG_CRYPTO_SPECK=.*|CONFIG_CRYPTO_SPECK=n|' \
                -i $pkg/trunk/config
            cd $pkg/trunk
                updpkgsums
            cd ../..

        ;;
        'licenses')
            sed -e 's|https://www.archlinux.org/|https://www.artixlinux.org/|' -i $pkg/trunk/PKGBUILD
        ;;
        'bash')
            sed -e 's|system.bash_logout)|system.bash_logout artix.bashrc)|' \
            -e "s|etc/bash.|etc/bash/|g" \
            -e 's|"$pkgdir/etc/skel/.bash_logout"|"$pkgdir/etc/skel/.bash_logout"\n  install -Dm644 artix.bashrc $pkgdir/etc/bash/bashrc.d/artix.bashrc|' \
            -i $pkg/trunk/PKGBUILD


            cd $pkg/trunk
                patch -Np 1 -i ${DATADIR}/patches/artix-bash.patch
                updpkgsums
            cd ../..
        ;;
        gstreamer|gst-plugins-*)
            sed -e 's|https://www.archlinux.org/|https://www.artixlinux.org/|' \
                -e 's|(Arch Linux)|(Artix Linux)|' \
                -i $pkg/trunk/PKGBUILD
        ;;
    esac
}

arch2artix(){
    local repo="$1" artix=none
    case "$repo" in
        core) artix=system ;;
        extra) artix=world ;;
        community) artix=galaxy ;;
        multilib) artix=lib32 ;;
        staging) artix=goblins ;;
        testing) artix=gremlins ;;
        community-staging) artix=galaxy-goblins ;;
        community-testing) artix=galaxy-gremlins ;;
        multilib-staging) artix=lib32-goblins ;;
        multilib-testing) artix=lib32-gremlins ;;
        kde-unstable) artix=kde-wobble ;;
        gnome-unstable) artix=gnome-wobble ;;
    esac
    echo $artix
}

find_tree(){
    local tree="$1" pkg="$2"
    local result=$(find $tree -mindepth 2 -maxdepth 2 -type d -name "$pkg")
    result=${result%/*}
    echo ${result##*/}
}

arch_repos(){
    local stag="$1" unst="$2"
    local repos=(core extra testing community community-testing multilib multilib-testing)

    $stag && repos+=(staging community-staging multilib-staging)
    $unst && repos+=(gnome-unstable kde-unstable)

    echo ${repos[@]}
}

find_repo(){
    local pkg="$1" stag="$2" unst="$3" repo=

    for r in $(arch_repos "$stag" "$unst");do
        [[ -f $pkg/repos/$r-${ARCH}/PKGBUILD ]] && repo=$r-${ARCH}
        [[ -f $pkg/repos/$r-any/PKGBUILD ]] && repo=$r-any
    done
    echo $repo
}

is_valid_repo(){
    local src="$1" cases=
    for r in $(arch_repos true true);do
        cases=${cases:-}${cases:+|}${r}
    done
    eval "case $src in
        ${cases}|trunk) return 0 ;;
        *) return 1 ;;
    esac"
}

get_cases(){
    local pkglist="${SYSCONFDIR}/pkglist.d/$1.list"

    local _space="s| ||g" _clean=':a;N;$!ba;s/\n/ /g' _com_rm="s|#.*||g"

    local pkgs=($(sed "$_com_rm" "$pkglist" | sed "$_space" | sed "$_clean"))

    local cases=
    for p in ${pkgs[@]};do
        cases=${cases:-}${cases:+|}${p}
    done
    echo $cases
}

get_artix_tree(){
    local pkg="$1" artix_tree="${2:-$3}" tree
    eval "case $pkg in
        $(get_cases kernel)) tree=packages-kernel ;;
        $(get_cases python)) tree=packages-python ;;
        $(get_cases perl)) tree=packages-perl ;;
        $(get_cases ruby)) tree=packages-ruby ;;
        $(get_cases openrc)) tree=packages-openrc ;;
        $(get_cases runit)) tree=packages-runit ;;
        $(get_cases media)) tree=packages-media ;;
        $(get_cases xorg)) tree=packages-xorg ;;
        $(get_cases qt5)) tree=packages-qt5 ;;
        $(get_cases gtk)) tree=packages-gtk ;;
        $(get_cases devel)) tree=packages-devel ;;
        $(get_cases lxqt)) tree=packages-lxqt ;;
        $(get_cases cinnamon)) tree=packages-cinnamon ;;
        $(get_cases kde)) tree=packages-kde ;;
        $(get_cases gnome)) tree=packages-gnome ;;
        $(get_cases mate)) tree=packages-mate ;;
        *) tree=$artix_tree
    esac"
    echo $tree
}

get_import_path(){
    local pkg="$1" import_path=
    for tree in ${TREE_NAMES_ARCH[@]};do
        [[ -d ${TREE_DIR_ARCH}/$tree/$pkg/repos ]] && import_path=${TREE_DIR_ARCH}/$tree/$pkg
    done
    echo $import_path
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

        for pkg in "$dir"/*.pkg.tar.?z; do
            [[ -f $pkg ]] || continue

            # avoid adding duplicates of the same inode
            for r in "${results[@]}"; do
                [[ $r -ef $pkg ]] && continue 2
            done

            # split apart package filename into parts
            pkgbasename=${pkg##*/}
            pkgbasename=${pkgbasename%.pkg.tar.?z}

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
