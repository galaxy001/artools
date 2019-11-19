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

make_sig () {
    local file="$1"
    msg2 "Creating signature file..."
    cd ${iso_root}${live_dir}
    chown "${OWNER}:$(id --group ${OWNER})" "${iso_root}${live_dir}"
    su ${OWNER} -c "gpg --detach-sign --default-key ${GPG_KEY} $file"
    chown -R root "${iso_root}${live_dir}"
    cd ${OLDPWD}
}

make_checksum(){
    local file="$1"
    msg2 "Creating md5sum ..."
    cd ${iso_root}${live_dir}
    md5sum $file > $file.md5
    cd ${OLDPWD}
}

make_ext_img(){
    local src="$1"
    local size=32G
    local mnt="${mnt_dir}/${src##*/}"
    mkdir -p ${work_dir}/embed${live_dir}
    local extimg=${work_dir}/embed${live_dir}/${src##*/}.img

    msg2 "Creating ext4 image of %s ..." "${size}"
    truncate -s ${size} "${extimg}"
    local ext4_args=()
    ext4_args+=(-O ^has_journal,^resize_inode -E lazy_itable_init=0 -m 0)
    mkfs.ext4 ${ext4_args[@]} -F "${extimg}" &>/dev/null
    tune2fs -c 0 -i 0 "${extimg}" &> /dev/null
    mount_img "${extimg}" "${mnt}"
    msg2 "Copying %s ..." "${src}/"
    cp -aT "${src}/" "${mnt}/"
    umount_img "${mnt}"
}

has_changed(){
    local src="$1" dest="$2"
    if [[ -f "${dest}" ]]; then
        local has_changes=$(find ${src} -newer ${dest})
        if [[ -n "${has_changes}" ]]; then
            msg2 "Possible changes for %s ..." "${src}"
            msg2 "%s" "${has_changes}"
            msg2 "SquashFS image %s is not up to date, rebuilding..." "${dest}"
            rm "${dest}"
        else
            msg2 "SquashFS image %s is up to date, skipping." "${dest}"
            return 1
        fi
    fi
}

# $1: image path
make_sfs() {
    local sfs_in="$1"
    if [[ ! -e "${sfs_in}" ]]; then
        error "The path %s does not exist" "${sfs_in}"
        retrun 1
    fi
    local timer=$(get_timer)

    mkdir -p ${iso_root}${live_dir}

    local img_name=${sfs_in##*/}.img
    local img_file=${sfs_in}.img

    local sfs_out="${iso_root}${live_dir}/${img_name}"

    if has_changed "${sfs_in}" "${sfs_out}"; then

        msg "Generating SquashFS image for %s" "${sfs_in}"

        local mksfs_args=()

        if ${persist};then
            make_ext_img "${sfs_in}"
            mksfs_args+=("${work_dir}/embed")
        else
            mksfs_args+=("${sfs_in}")
        fi

        mksfs_args+=("${sfs_out}")

        mksfs_args+=(-comp xz -b 256K -Xbcj x86 -noappend)

        mksquashfs "${mksfs_args[@]}"

        if ! ${use_dracut}; then
            make_checksum "${img_name}"
            if [[ -n ${GPG_KEY} ]];then
                make_sig "${img_name}"
            fi
        fi
        ${persist} && rm -r "${work_dir}/embed"
    fi
    show_elapsed_time "${FUNCNAME}" "${timer_start}"
}

get_disturl(){
    . /usr/lib/os-release
    echo "${HOME_URL}"
}

assemble_iso(){
    msg "Creating ISO image..."
    local mod_date=$(date -u +%Y-%m-%d-%H-%M-%S-00  | sed -e s/-//g)
    local appid="$(get_osname) Live/Rescue CD"
    local publisher="$(get_osname) <$(get_disturl)>"

    xorriso -as mkisofs \
        --modification-date=${mod_date} \
        --protective-msdos-label \
        -volid "${iso_label}" \
        -appid "${appid}" \
        -publisher "${publisher}" \
        -preparer "Prepared by artools/${0##*/}" \
        -r -graft-points -no-pad \
        --sort-weight 0 / \
        --sort-weight 1 /boot \
        --grub2-mbr ${iso_root}/boot/grub/i386-pc/boot_hybrid.img \
        -partition_offset 16 \
        -b boot/grub/i386-pc/eltorito.img \
        -c boot.catalog \
        -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
        -eltorito-alt-boot \
        -append_partition 2 0xef ${iso_root}/boot/efi.img \
        -e --interval:appended_partition_2:all:: -iso_mbr_part_type 0x00 \
        -no-emul-boot \
        -iso-level 3 \
        -o ${iso_dir}/${iso_file} \
        ${iso_root}/
}

make_iso() {
    msg "Start [Build ISO]"
    touch "${iso_root}/.artix"
    make_sfs "${work_dir}/rootfs"
    [[ -d "${work_dir}/livefs" ]] && make_sfs "${work_dir}/livefs"

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
