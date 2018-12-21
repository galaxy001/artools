#!/bin/bash
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

get_local_head(){
    echo $(git log --pretty=%H ...refs/heads/$1^ | head -n 1)
}

get_remote_head(){
    echo $(git ls-remote origin -h refs/heads/$1 | cut -f1)
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

get_compliant_name(){
    local gitname="$1"
    case $gitname in
        *+) gitname=${gitname//+/plus}
    esac
    echo $gitname
}

find_tree(){
    local tree="$1" pkg="$2"
    local result=$(find $tree -mindepth 2 -maxdepth 2 -type d -name "$pkg")
    result=${result%/*}
    echo ${result##*/}
}

find_repo(){
    local pkg="$1" unst="$2" stag="$3" repo=
    local repos=(core extra testing community community-testing multilib multilib-testing)

    $stag && repos+=(staging community-staging multilib-staging)
    $unst && repos+=(gnome-unstable kde-unstable)

    for r in ${repos[@]};do
        [[ -f $pkg/repos/$r-x86_64/PKGBUILD ]] && repo=$r-x86_64
        [[ -f $pkg/repos/$r-any/PKGBUILD ]] && repo=$r-any
    done
    echo $repo
}

get_import_path(){
    local pkg="$1" import_path=
    for tree in ${tree_names[@]};do
        [[ -d ${TREE_DIR_ARCH}/$tree/$pkg ]] && import_path=${TREE_DIR_ARCH}/$tree/$pkg
    done
    echo $import_path
}

clone_tree(){
    local timer=$(get_timer) host_tree="$1"
    git clone $host_tree.git
    show_elapsed_time "${FUNCNAME}" "${timer}"
}

pull_tree(){
    local branch="master"
    local local_head=$(get_local_head "$branch")
    local remote_head=$(get_remote_head "$branch")
    if [[ "${local_head}" == "${remote_head}" ]]; then
        msg2 "remote changes: no"
    else
        msg2 "remote changes: yes"
        git pull origin "$branch"
    fi
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
