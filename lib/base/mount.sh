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

ignore_error() {
    "$@" 2>/dev/null
    return 0
}

parse_fstab(){
    echo $(perl -ane 'printf("%s:%s\n", @F[0,1]) if $F[0] =~ m#^UUID=#;' $1/etc/fstab)
# 	perl -ane 'printf("%s:%s\n", @F[0,1]) if $F[0] =~ m#^/dev#;' $1/etc/fstab
# 	perl -ane 'printf("%s:%s\n", @F[0,1]) if $F[0] =~ m#^LABEL=#;' $1/etc/fstab
}

detect(){
    local detected="$(os-prober | tr ' ' '_' | paste -s -d ' ')"
    echo ${detected}
}

# $1: os-prober array
get_os_name(){
    local str=$1
    str="${str#*:}"
    str="${str#*:}"
    str="${str%:*}"
    echo "$str"
}

chroot_part_mount() {
    info "mount: [%s]" "$2"
    mount "$@" && CHROOT_ACTIVE_PART_MOUNTS=("$2" "${CHROOT_ACTIVE_PART_MOUNTS[@]}")
}

trap_setup(){
    [[ $(trap -p EXIT) ]] && die 'Error! Attempting to overwrite existing EXIT trap'
    trap "$1" EXIT
}

chroot_mount() {
#     info "mount: [%s]" "$2"
    mount "$@" && CHROOT_ACTIVE_MOUNTS=("$2" "${CHROOT_ACTIVE_MOUNTS[@]}")
}

chroot_add_resolv_conf() {
    local chrootdir=$1 resolv_conf=$1/etc/resolv.conf

    [[ -e /etc/resolv.conf ]] || return 0

    # Handle resolv.conf as a symlink to somewhere else.
    if [[ -L $chrootdir/etc/resolv.conf ]]; then
        # readlink(1) should always give us *something* since we know at this point
        # it's a symlink. For simplicity, ignore the case of nested symlinks.
        resolv_conf=$(readlink "$chrootdir/etc/resolv.conf")
        if [[ $resolv_conf = /* ]]; then
            resolv_conf=$chrootdir$resolv_conf
        else
            resolv_conf=$chrootdir/etc/$resolv_conf
        fi

        # ensure file exists to bind mount over
        if [[ ! -f $resolv_conf ]]; then
            install -Dm644 /dev/null "$resolv_conf" || return 1
        fi
    elif [[ ! -e $chrootdir/etc/resolv.conf ]]; then
        # The chroot might not have a resolv.conf.
        return 0
    fi

    chroot_mount /etc/resolv.conf "$resolv_conf" --bind
}

chroot_mount_conditional() {
    local cond=$1; shift
    if eval "$cond"; then
        chroot_mount "$@"
    fi
}

chroot_setup(){
    chroot_mount_conditional "! mountpoint -q '$1'" "$1" "$1" --bind &&
    chroot_mount proc "$1/proc" -t proc -o nosuid,noexec,nodev &&
    chroot_mount sys "$1/sys" -t sysfs -o nosuid,noexec,nodev,ro &&
    ignore_error chroot_mount_conditional "[[ -d '$1/sys/firmware/efi/efivars' ]]" \
        efivarfs "$1/sys/firmware/efi/efivars" -t efivarfs -o nosuid,noexec,nodev &&
    chroot_mount udev "$1/dev" -t devtmpfs -o mode=0755,nosuid &&
    chroot_mount devpts "$1/dev/pts" -t devpts -o mode=0620,gid=5,nosuid,noexec &&
    chroot_mount shm "$1/dev/shm" -t tmpfs -o mode=1777,nosuid,nodev &&
    chroot_mount run "$1/run" -t tmpfs -o nosuid,nodev,mode=0755 &&
    chroot_mount tmp "$1/tmp" -t tmpfs -o mode=1777,strictatime,nodev,nosuid
}

mount_os(){
    CHROOT_ACTIVE_PART_MOUNTS=()
    CHROOT_ACTIVE_MOUNTS=()

    trap_setup chroot_part_umount

    chroot_part_mount "$2" "$1"

    local mounts=$(parse_fstab "$1")

    for entry in ${mounts[@]}; do
        entry=${entry//UUID=}
        local dev=${entry%:*} mp=${entry#*:}
        case "${entry#*:}" in
            '/'|'swap'|'none') continue ;;
            *) chroot_part_mount "/dev/disk/by-uuid/${dev}" "$1${mp}" ;;
        esac
    done

    chroot_setup "$1"
    chroot_add_resolv_conf "$1"
}

chroot_api_mount() {
    CHROOT_ACTIVE_MOUNTS=()
    trap_setup chroot_api_umount
    chroot_setup "$1"
}

chroot_api_umount() {
    if (( ${#CHROOT_ACTIVE_MOUNTS[@]} )); then
#         info "umount: [%s]" "${CHROOT_ACTIVE_MOUNTS[@]}"
        umount "${CHROOT_ACTIVE_MOUNTS[@]}"
    fi
    unset CHROOT_ACTIVE_MOUNTS
}

chroot_part_umount() {
    chroot_api_umount
    info "umount: [%s]" "${CHROOT_ACTIVE_PART_MOUNTS[@]}"
    umount "${CHROOT_ACTIVE_PART_MOUNTS[@]}"
    unset CHROOT_ACTIVE_PART_MOUNTS
}

