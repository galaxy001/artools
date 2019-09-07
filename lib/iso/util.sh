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
    if [[ -p $logpipe ]]; then
        rm "$logpipe"
    fi
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

# Build ISO
make_iso() {
    msg "Start [Build ISO]"
    touch "${iso_root}/.artix"
    for sfs_dir in $(find "${work_dir}" -maxdepth 1 -type d); do
        if [[ "${sfs_dir}" != "${work_dir}" ]]; then
            make_sfs "${sfs_dir}"
        fi
    done

    msg "Making bootable image"
    # Sanity checks
    [[ ! -d "${iso_root}" ]] && return 1
    if [[ -f "${iso_dir}/${iso_file}" ]]; then
        msg2 "Removing existing bootable image..."
        rm -rf "${iso_dir}/${iso_file}"
    fi
    assemble_iso
    msg "Done [Build ISO]"
}

copy_overlay(){
    local src="$1" dest="$2"
    if [[ -e "$src" ]];then
        msg2 "Copying [%s] ..." "${src##*/}"
        cp -LR "$src"/* "$dest"
    fi
}

clean_up_image(){
    local path mnt="$1"
    msg2 "Cleaning [%s]" "${mnt##*/}"

    path=$mnt/boot
    if [[ -d "$path" ]]; then
        find "$path" -name 'initramfs*.img' -delete &> /dev/null
    fi
    path=$mnt/var/lib/pacman/sync
    if [[ -d $path ]];then
        find "$path" -type f -delete &> /dev/null
    fi
    path=$mnt/var/cache/pacman/pkg
    if [[ -d $path ]]; then
        find "$path" -type f -delete &> /dev/null
    fi
    path=$mnt/var/log
    if [[ -d $path ]]; then
        find "$path" -type f -delete &> /dev/null
    fi
    path=$mnt/var/tmp
    if [[ -d $path ]];then
        find "$path" -mindepth 1 -delete &> /dev/null
    fi
    path=$mnt/tmp
    if [[ -d $path ]];then
        find "$path" -mindepth 1 -delete &> /dev/null
    fi
    find "$mnt" -name *.pacnew -name *.pacsave -name *.pacorig -delete
    if [[ -f "$mnt/boot/grub/grub.cfg" ]]; then
        rm $mnt/boot/grub/grub.cfg
    fi
    if [[ -f "$mnt/etc/machine-id" ]]; then
        rm $mnt/etc/machine-id
    fi
}

make_rootfs() {
    if [[ ! -e ${work_dir}/rootfs.lock ]]; then
        msg "Prepare [Base installation] (rootfs)"
        local rootfs="${work_dir}/rootfs"

        prepare_dir "${rootfs}"

        basestrap "${basestrap_args[@]}" "${rootfs}" "${packages[@]}"

        copy_overlay "${ROOT_OVERLAY}" "${rootfs}"

        [[ -z ${LIVE_LIST} ]] && configure_image "${rootfs}"

        clean_up_image "${rootfs}"

        : > ${work_dir}/rootfs.lock

        msg "Done [Base installation] (rootfs)"
    fi
}

make_livefs() {
    if [[ ! -e ${work_dir}/livefs.lock ]]; then
        msg "Prepare [Live installation] (livefs)"
        local livefs="${work_dir}/livefs"

        prepare_dir "${livefs}"

        mount_overlay "${livefs}" "${work_dir}"

        basestrap "${basestrap_args[@]}" "${livefs}" "${packages[@]}"

        copy_overlay "${LIVE_OVERLAY}" "${livefs}"

        configure_image "${livefs}"

        umount_overlay

        clean_up_image "${livefs}"

        : > ${work_dir}/livefs.lock

        msg "Done [Live installation] (livefs)"
    fi
}

make_bootfs() {
    if [[ ! -e ${work_dir}/bootfs.lock ]]; then
        msg "Prepare [/iso/boot]"
        local boot="${iso_root}/boot"

        prepare_dir "${boot}"

        cp ${work_dir}/rootfs/boot/vmlinuz* ${boot}/vmlinuz-${ARCH}

        local bootfs="${work_dir}/bootfs"

        mount_overlay "${bootfs}" "${work_dir}"

        prepare_initcpio "${bootfs}"
        prepare_initramfs "${bootfs}"

        cp ${bootfs}/boot/initramfs.img ${boot}/initramfs-${ARCH}.img
        prepare_boot_extras "${bootfs}" "${boot}"

        umount_overlay

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

        prepare_grub "${work_dir}/rootfs" "$layer" "${iso_root}"

        configure_grub "${iso_root}"

        : > ${work_dir}/grub.lock
        msg "Done [/iso/boot/grub]"
    fi
}

compress_images(){
    local timer=$(get_timer)
    run_safe "make_iso"
    chown -R "${OWNER}:$(id --group ${OWNER})" "${iso_dir}"
    show_elapsed_time "${FUNCNAME}" "${timer}"
}

prepare_images(){
    local timer=$(get_timer)
    load_pkgs "${ROOT_LIST}" "${INITSYS}"
    run_safe "make_rootfs"
    if [[ -n ${LIVE_LIST} ]]; then
        load_pkgs "${LIVE_LIST}" "${INITSYS}"
        run_safe "make_livefs"
    fi
    run_safe "make_bootfs"
    run_safe "make_grub"

    show_elapsed_time "${FUNCNAME}" "${timer}"
}
