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

track_img() {
    info "mount: [%s]" "$2"
    mount "$@" && IMG_ACTIVE_MOUNTS=("$2" "${IMG_ACTIVE_MOUNTS[@]}")
}

mount_img() {
    IMG_ACTIVE_MOUNTS=()
    mkdir -p "$2"
    track_img "$1" "$2"
}

umount_img() {
    if [[ -n ${IMG_ACTIVE_MOUNTS[@]} ]];then
        info "umount: [%s]" "${IMG_ACTIVE_MOUNTS[@]}"
        umount "${IMG_ACTIVE_MOUNTS[@]}"
        unset IMG_ACTIVE_MOUNTS
        rm -r "$1"
    fi
}

track_fs() {
    info "overlayfs mount: [%s]" "$5"
    mount "$@" && FS_ACTIVE_MOUNTS=("$5" "${FS_ACTIVE_MOUNTS[@]}")
}

mount_overlay(){
    FS_ACTIVE_MOUNTS=()
    local lower= upper="$1" work="$2"
    mkdir -p "${mnt_dir}/work"
    mkdir -p "$upper"
    case $upper in
        */livefs) lower="$work/rootfs" ;;
        */bootfs) lower="$work/livefs":"$work/rootfs" ;;
    esac
    track_fs -t overlay overlay -olowerdir="$lower",upperdir="$upper",workdir="${mnt_dir}/work" "$upper"
}

umount_overlay(){
    if [[ -n ${FS_ACTIVE_MOUNTS[@]} ]];then
        info "overlayfs umount: [%s]" "${FS_ACTIVE_MOUNTS[@]}"
        umount "${FS_ACTIVE_MOUNTS[@]}"
        unset FS_ACTIVE_MOUNTS
        rm -rf "${mnt_dir}/work"
    fi
}
