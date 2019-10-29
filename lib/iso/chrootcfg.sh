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

add_svc_rc(){
    local mnt="$1" name="$2" rlvl="$3"
    if [[ -f $mnt/etc/init.d/$name ]];then
        msg2 "Setting %s ..." "$name"
        chroot $mnt rc-update add $name $rlvl &>/dev/null
    fi
}

add_svc_runit(){
    local mnt="$1" name="$2"
    if [[ -d $mnt/etc/runit/sv/$name ]]; then
        msg2 "Setting %s ..." "$name"
        chroot $mnt ln -s /etc/runit/sv/$name /etc/runit/runsvdir/default &>/dev/null
    fi
}

add_svc_s6(){
    local mnt="$1" names="$2" valid=""
    for svc in $names; do
        if [[ -d $mnt/etc/s6/sv/$svc ]]; then
            msg2 "Setting %s ..." "$svc"
            valid+=$svc
            valid+=" "
        fi
    done
    chroot $mnt s6-rc-bundle -c /etc/s6/rc/compiled add default $valid
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
    info "Configuring [%s]" "${INITSYS}"
    case ${INITSYS} in
        'openrc')
            for svc in ${SERVICES[@]}; do
                [[ $svc == "xdm" ]] && set_xdm "$mnt"
                add_svc_rc "$mnt" "$svc" "default"
            done
            for svc in ${SERVICES_LIVE[@]}; do
                add_svc_rc "$mnt" "$svc" "default"
            done
        ;;
        'runit')
            for svc in ${SERVICES[@]}; do
                add_svc_runit "$mnt" "$svc"
            done
            for svc in ${SERVICES_LIVE[@]}; do
                add_svc_runit "$mnt" "$svc"
            done
        ;;
        's6')
            local svcs="${SERVICES[@]} ${SERVICES_LIVE[@]}"
            add_svc_s6 "$mnt" "$svcs"
        ;;
    esac
    info "Done configuring [%s]" "${INITSYS}"
}

configure_system(){
    local mnt="$1"
    case ${INITSYS} in
        'openrc' | 'runit'|'s6')
            configure_logind "$mnt" "elogind"
        ;;
    esac
    echo ${HOST_NAME} > $mnt/etc/hostname
}

write_users_conf(){
    local yaml=$(write_yaml_header)
    yaml+=$(write_empty_line)
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

write_servicescfg_conf(){
    local yaml=$(write_yaml_header)
    yaml+=$(write_empty_line)
    case "${INITSYS}" in
        'runit')
            yaml+=$(write_yaml_map 0 'svDir' '/etc/runit/sv')
            yaml+=$(write_yaml_map 0 'runsvDir' '/etc/runit/runsvdir')
            yaml+=$(write_yaml_map 0 'services')
            yaml+=$(write_yaml_map 2 'enabled')
            for svc in ${SERVICES[@]};do
                yaml+=$(write_yaml_seq_map 4 'name' "$svc")
                yaml+=$(write_yaml_map 6 'runlevel' 'default')
            done
        ;;
        'openrc')
            yaml+=$(write_yaml_map 0 'initdDir' '/etc/init.d')
            yaml+=$(write_yaml_map 0 'runlevelsDir' '/etc/runlevels')
            yaml+=$(write_yaml_map 0 'services')
            for svc in ${SERVICES[@]};do
                yaml+=$(write_yaml_seq_map 2 'name' "$svc")
                yaml+=$(write_yaml_map 4 'runlevel' 'default')
            done
        ;;
        's6')
            yaml+=$(write_yaml_map 0 'svDir' '/etc/s6/sv')
            yaml+=$(write_yaml_map 0 'rcDir' '/etc/s6/rc')
            yaml+=$(write_yaml_map 0 'services')
            for svc in ${SERVICES[@]};do
                yaml+=$(write_yaml_seq_map 2 'name' "$svc")
                yaml+=$(write_yaml_map 4 'bundle' 'default')
            done
        ;;
    esac
    yaml+=$(write_empty_line)
    printf '%s' "${yaml}"
}

write_unpackfs_conf(){
    local yaml=$(write_yaml_header)
    yaml+=$(write_empty_line)
    yaml+=$(write_yaml_map 0 'unpack')
    yaml+=$(write_yaml_seq_map 2 'source' "/run/artix/bootmnt/artix/x86_64/rootfs.sfs")
    yaml+=$(write_yaml_map 4 'sourcefs' 'squashfs')
    yaml+=$(write_yaml_map 4 'destination' '""')
    yaml+=$(write_empty_line)
    printf '%s' "${yaml}"
}

configure_calamares(){
    local mods="$1/etc/calamares/modules"
    if [[ -d "$mods" ]];then
        msg2 "Configuring Calamares"
        write_users_conf > "$mods"/users.conf
        write_servicescfg_conf > "$mods"/services-"${INITSYS}".conf
        write_unpackfs_conf > "$mods"/unpackfs.conf
        sed -e "s|openrc|${INITSYS}|" -i "$mods"/postcfg.conf
        sed -e "s|services-openrc|services-${INITSYS}|" -i "$1"/etc/calamares/settings.conf
    fi
}

configure_image(){
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
