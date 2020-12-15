#!/hint/bash

#{{{ initcpio

write_mkinitcpio_conf() {
    msg2 "Writing mkinitcpio.conf ..."
    local conf="$1/etc/mkinitcpio-artix.conf"
    printf "%s\n" 'MODULES=(loop dm-snapshot)' > "$conf"
    printf "%s\n" 'COMPRESSION="xz"' >> "$conf"
    if [[ "${profile}" == 'base' ]];then
        printf "%s\n" 'HOOKS=(base udev artix_shutdown artix artix_loop_mnt
                            artix_pxe_common artix_pxe_http artix_pxe_nbd artix_pxe_nfs
                            artix_kms modconf block filesystems keyboard keymap)' >> "$conf"
    else
        printf "%s\n" 'HOOKS=(base udev artix_shutdown artix artix_loop_mnt
                            artix_kms modconf block filesystems keyboard keymap)' >> "$conf"
    fi
}

prepare_initcpio(){
    msg2 "Copying initcpio ..."
    local dest="$1"
    cp /etc/initcpio/hooks/artix* "$dest"/etc/initcpio/hooks
    cp /etc/initcpio/install/artix* "$dest"/etc/initcpio/install
    cp /etc/initcpio/artix_shutdown "$dest"/etc/initcpio
}

prepare_initramfs(){
    local mnt="$1"

    prepare_initcpio "$mnt"

    write_mkinitcpio_conf "$mnt"

    if [[ -n ${GPG_KEY} ]]; then
        su "${owner}" -c "gpg --export ${GPG_KEY} >/tmp/GPG_KEY"
        exec 17<>/tmp/GPG_KEY
    fi
    local _kernel
     _kernel=$(<"$mnt"/usr/src/linux/version)
    ARTIX_GNUPG_FD=${GPG_KEY:+17} artools-chroot "$mnt" \
        /usr/bin/mkinitcpio -k "${_kernel}" \
        -c /etc/mkinitcpio-artix.conf \
        -g /boot/initramfs.img

    if [[ -n "${GPG_KEY}" ]]; then
        exec 17<&-
    fi
    if [[ -f /tmp/GPG_KEY ]]; then
        rm /tmp/GPG_KEY
    fi

    cp "$mnt"/boot/initramfs.img "${iso_root}"/boot/initramfs-"${arch}".img
    prepare_boot_extras "$mnt"
}

#}}}
