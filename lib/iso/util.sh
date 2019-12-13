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

error_function() {
    local func="$1"
    # first exit all subshells, then print the error
    if (( ! BASH_SUBSHELL )); then
        error "A failure occurred in %s()." "$func"
        plain "Aborting..."
    fi
    umount_overlay
    umount_img
    exit 2
}

run_safe() {
    local restoretrap func="$1"
    set -e
    set -E
    restoretrap=$(trap -p ERR)
    trap 'error_function $func' ERR

    "$func"

    eval $restoretrap
    set +E
    set +e
}

trap_exit() {
    local sig=$1; shift
    error "$@"
    umount_overlay
    trap -- "$sig"
    kill "-$sig" "$$"
}

prepare_traps(){
    for sig in TERM HUP QUIT; do
        trap "trap_exit $sig \"$(gettext "%s signal caught. Exiting...")\" \"$sig\"" "$sig"
    done
    trap 'trap_exit INT "$(gettext "Aborted by user! Exiting...")"' INT
#     trap 'trap_exit USR1 "$(gettext "An unknown error has occurred. Exiting...")"' ERR
}

copy_overlay(){
    local src="$1" dest="$2"
    if [[ -e "$src" ]];then
        msg2 "Copying [%s] ..." "${src##*/}"
        cp -LR "$src"/* "$dest"
    fi
}

make_rootfs() {
    if [[ ! -e ${work_dir}/rootfs.lock ]]; then
        msg "Prepare [Base installation] (rootfs)"
        local rootfs="${work_dir}/rootfs"

        prepare_dir "${rootfs}"

        basestrap "${basestrap_args[@]}" "${rootfs}" "${packages[@]}"

        copy_overlay "${ROOT_OVERLAY}" "${rootfs}"

        [[ -z ${LIVE_LIST} ]] && configure_chroot "${rootfs}"

        clean_up_chroot "${rootfs}"

        : > ${work_dir}/rootfs.lock

        msg "Done [Base installation] (rootfs)"
    fi
}

make_livefs() {
    if [[ ! -e ${work_dir}/livefs.lock ]]; then
        msg "Prepare [Live installation] (livefs)"
        local livefs="${work_dir}/livefs"

        prepare_dir "${livefs}"

        mount_overlayfs "${livefs}" "${work_dir}"

        basestrap "${basestrap_args[@]}" "${livefs}" "${packages[@]}"

        copy_overlay "${LIVE_OVERLAY}" "${livefs}"

        configure_chroot "${livefs}"

        umount_overlayfs

        clean_up_chroot "${livefs}"

        : > ${work_dir}/livefs.lock

        msg "Done [Live installation] (livefs)"
    fi
}

make_bootfs() {
    if [[ ! -e ${work_dir}/bootfs.lock ]]; then
        msg "Prepare [/iso/boot]"

        prepare_dir "${iso_root}/boot"

        cp ${work_dir}/rootfs/boot/vmlinuz* ${iso_root}/boot/vmlinuz-${ARCH}

        local bootfs="${work_dir}/bootfs"

        mount_overlayfs "${bootfs}" "${work_dir}"

        if ${use_dracut}; then
            prepare_initramfs_dracut "${bootfs}"
        else
            prepare_initramfs "${bootfs}"
        fi

        umount_overlayfs

        rm -R ${bootfs}
        : > ${work_dir}/bootfs.lock
        msg "Done [/iso/boot]"
    fi
}

make_grub(){
    if [[ ! -e ${work_dir}/grub.lock ]]; then
        msg "Prepare [/iso/boot/grub]"

        local layer=${work_dir}/rootfs
        [[ -n ${LIVE_LIST} ]] && layer=${work_dir}/livefs

        prepare_grub "${work_dir}/rootfs" "$layer"

        if ${use_dracut}; then
            configure_grub_dracut
        else
            configure_grub
        fi

        : > ${work_dir}/grub.lock
        msg "Done [/iso/boot/grub]"
    fi
}
