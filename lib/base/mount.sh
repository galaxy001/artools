#!/hint/bash

#{{{ mount

ignore_error() {
    "$@" 2>/dev/null
    return 0
}

trap_setup(){
    [[ $(trap -p EXIT) ]] && die 'Error! Attempting to overwrite existing EXIT trap'
    trap "$1" EXIT
}

chroot_mount() {
#     msg2 "mount: [%s]" "$2"
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
    local mnt="$1" os="$2" args='-t tmpfs -o nosuid,nodev,mode=0755'
    $os && args='--bind'
    chroot_mount_conditional "! mountpoint -q '$mnt'" "$mnt" "$mnt" --bind &&
    chroot_mount proc "$mnt/proc" -t proc -o nosuid,noexec,nodev &&
    chroot_mount sys "$mnt/sys" -t sysfs -o nosuid,noexec,nodev,ro &&
    ignore_error chroot_mount_conditional "[[ -d '$mnt/sys/firmware/efi/efivars' ]]" \
        efivarfs "$mnt/sys/firmware/efi/efivars" -t efivarfs -o nosuid,noexec,nodev &&
    chroot_mount udev "$mnt/dev" -t devtmpfs -o mode=0755,nosuid &&
    chroot_mount devpts "$mnt/dev/pts" -t devpts -o mode=0620,gid=5,nosuid,noexec &&
    chroot_mount shm "$mnt/dev/shm" -t tmpfs -o mode=1777,nosuid,nodev &&
    chroot_mount /run "$mnt/run" ${args} &&
    chroot_mount tmp "$mnt/tmp" -t tmpfs -o mode=1777,strictatime,nodev,nosuid
}

chroot_api_mount() {
    CHROOT_ACTIVE_MOUNTS=()
    trap_setup chroot_api_umount
    chroot_setup "$1" false
}

chroot_api_umount() {
    if (( ${#CHROOT_ACTIVE_MOUNTS[@]} )); then
#         msg2 "umount: [%s]" "${CHROOT_ACTIVE_MOUNTS[@]}"
        umount "${CHROOT_ACTIVE_MOUNTS[@]}"
    fi
    unset CHROOT_ACTIVE_MOUNTS
}

#}}}
