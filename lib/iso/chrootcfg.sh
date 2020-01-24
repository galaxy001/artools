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

add_svc_openrc(){
    local mnt="$1" names="$2" rlvl="${3:-default}"
    for svc in $names; do
        if [[ -f $mnt/etc/init.d/$svc ]];then
            msg2 "Setting %s ..." "$svc"
            [[ $svc == "xdm" ]] && set_xdm "$mnt"
            chroot $mnt rc-update add $svc $rlvl &>/dev/null
        fi
    done
}

add_svc_runit(){
    local mnt="$1" names="$2" rlvl="${3:-default}"
    for svc in $names; do
        if [[ -d $mnt/etc/runit/sv/$svc ]]; then
            msg2 "Setting %s ..." "$svc"
            chroot $mnt ln -s /etc/runit/sv/$svc /etc/runit/runsvdir/$rlvl &>/dev/null
        fi
    done
}

add_svc_s6(){
    local mnt="$1" names="$2" valid="" rlvl="${3:-default}"
    for svc in $names; do
        if [[ -d $mnt/etc/s6/sv/$svc ]]; then
            msg2 "Setting %s ..." "$svc"
            valid=${valid:-}${valid:+' '}${svc}
        fi
    done
    chroot $mnt s6-rc-bundle -c /etc/s6/rc/compiled add $rlvl $valid

    # rebuild s6-linux-init binaries
    chroot $mnt rm -r /etc/s6/current
    chroot $mnt s6-linux-init-maker -1 -N -f etc/s6/skel -G "/usr/bin/agetty -L -8 tty1 115200" -c /etc/s6/current /etc/s6/current
    chroot $mnt mv /etc/s6/current/bin/init /etc/s6/current/bin/s6-init
    chroot $mnt cp -a /etc/s6/current/bin /usr
}

set_xdm(){
    if [[ -f $1/etc/conf.d/xdm ]];then
        local conf='DISPLAYMANAGER="'${DISPLAYMANAGER}'"'
        sed -i -e "s|^.*DISPLAYMANAGER=.*|${conf}|" $1/etc/conf.d/xdm
    fi
}

configure_hosts(){
    sed -e "s|localhost.localdomain|localhost.localdomain ${HOST_NAME}|" -i $1/etc/hosts
}

configure_logind(){
    local conf=$1/etc/$2/logind.conf
    if [[ -e $conf ]];then
        msg2 "Configuring logind ..."
        sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' "$conf"
        sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' "$conf"
        sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' "$conf"
    fi
}

configure_services(){
    local mnt="$1"
    info "Configuring [%s] services" "${INITSYS}"
    add_svc_${INITSYS} "$mnt" "${SERVICES[*]} ${SERVICES_LIVE[*]}"
    info "Done configuring [%s] services" "${INITSYS}"
}

configure_system(){
    local mnt="$1"
    configure_logind "$mnt" "elogind"
    echo ${HOST_NAME} > $mnt/etc/hostname
}

write_users_conf(){
    local yaml=$(write_yaml_header)
    yaml+=$(write_yaml_map 0 'defaultGroups')
    local IFS=','
    for g in ${ADDGROUPS[@]};do
        yaml+=$(write_yaml_seq 2 "$g")
    done
    unset IFS
    yaml+=$(write_yaml_map 0 'autologinGroup' 'autologin')
    yaml+=$(write_yaml_map 0 'doAutologin' 'false')
    yaml+=$(write_yaml_map 0 'sudoersGroup' 'wheel')
    yaml+=$(write_yaml_map 0 'setRootPassword' 'true')
    yaml+=$(write_yaml_map 0 'availableShells' '/bin/bash, /bin/zsh')
#     yaml+=$(write_yaml_map 0 'passwordRequirements')
#     yaml+=$(write_yaml_map 2 'minLength' '-1')
#     yaml+=$(write_yaml_map 2 'maxLength' '-1')
#     yaml+=$(write_yaml_map 2 'libpwquality')
#     yaml+=$(write_yaml_seq 4 "minlen=8")
#     yaml+=$(write_yaml_seq 4 "minclass=80")
    yaml+=$(write_empty_line)
    printf '%s' "${yaml}"
}

write_services_conf(){
    local key1="$1" val1="$2" key2="$3" val2="$4"
    local yaml=$(write_yaml_header)
    yaml+=$(write_yaml_map 0 "$key1" "$val1")
    yaml+=$(write_yaml_map 0 "$key2" "$val2")
    yaml+=$(write_yaml_map 0 'services')
    for svc in ${SERVICES[@]};do
        yaml+=$(write_yaml_seq 2 "$svc")
    done
    yaml+=$(write_empty_line)
    printf '%s' "${yaml}"
}

write_services_openrc_conf(){
    local conf="$1"/services-openrc.conf
    write_services_conf 'initdDir' '/etc/init.d' 'runlevelsDir' '/etc/runlevels' > "$conf"
}

write_services_runit_conf(){
    local conf="$1"/services-runit.conf
    write_services_conf 'svDir' '/etc/runit/sv' 'runsvDir' '/etc/runit/runsvdir' > "$conf"
}

write_services_s6_conf(){
    local conf="$1"/services-s6.conf
    write_services_conf 'svDir' '/etc/s6/sv' 'dbDir' '/etc/s6/rc/compiled' > "$conf"
}

write_postcfg(){
    local yaml=$(write_yaml_header)
    yaml+=$(write_yaml_map 0 'keyrings')
    for k in archlinux artix;do
        yaml+=$(write_yaml_seq 2 "$k")
    done
    yaml+=$(write_empty_line)
    printf '%s' "${yaml}"
}

write_unpackfs() {
    local yaml=$(write_yaml_header)
    yaml+=$(write_yaml_map 0 'unpack')
#     if ${persist}; then
#         yaml+=$(write_yaml_seq_map 2 'source' '"/run/artix/bootmnt/LiveOS/rootfs.img"')
#         yaml+=$(write_yaml_map 4 'sourcefs' '"ext4"')
#     else
    yaml+=$(write_yaml_seq_map 2 'source' '"/run/artix/bootmnt/LiveOS/rootfs.img"')
    yaml+=$(write_yaml_map 4 'sourcefs' '"squashfs"')
#     fi
    yaml+=$(write_yaml_map 4 'destination' '""')
    yaml+=$(write_empty_line)
    printf '%s' "${yaml}"
}

configure_calamares(){
    local mods="$1/etc/calamares/modules"
    if [[ -d "$mods" ]];then
        msg2 "Configuring Calamares"
        write_users_conf > "$mods"/users.conf
        write_services_"${INITSYS}"_conf "$mods"
        write_postcfg > "$mods"/postcfg.conf
        write_unpackfs > "$mods"/unpackfs.conf
        sed -e "s|services-openrc|services-${INITSYS}|" \
            -i "$1"/etc/calamares/settings.conf
    fi
}

configure_chroot(){
    local fs="$1"
    msg "Configuring [%s]" "${fs##*/}"
    configure_hosts "$fs"
    configure_system "$fs"
    configure_services "$fs"
    configure_calamares "$fs"
    [[ ! -d "$fs/etc/artools" ]] && mkdir -p "$fs/etc/artools"
    msg2 "Writing live.conf"
    write_live_session_conf > "$fs/etc/artools/live.conf"
    msg "Done configuring [%s]" "${fs##*/}"
}

clean_up_chroot(){
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
