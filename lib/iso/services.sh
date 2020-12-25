#!/hint/bash

#{{{ services

set_xdm(){
    if [[ -f "$1"/etc/conf.d/xdm ]];then
        local conf='DISPLAYMANAGER="'${DISPLAYMANAGER}'"'
        sed -i -e "s|^.*DISPLAYMANAGER=.*|${conf}|" "$1"/etc/conf.d/xdm
    fi
}

add_svc_openrc(){
    local mnt="$1" names="$2" rlvl="${3:-default}"
    for svc in $names; do
        if [[ -f $mnt/etc/init.d/$svc ]];then
            msg2 "Setting [%s]: %s" "${INITSYS}" "$svc"
            [[ $svc == "xdm" ]] && set_xdm "$mnt"
            chroot "$mnt" rc-update add "$svc" "$rlvl" &>/dev/null
        fi
    done
}

add_svc_runit(){
    local mnt="$1" names="$2" rlvl="${3:-default}"
    for svc in $names; do
        if [[ -d $mnt/etc/runit/sv/$svc ]]; then
            msg2 "Setting [%s]: %s" "${INITSYS}" "$svc"
            chroot "$mnt" ln -s /etc/runit/sv/"$svc" /etc/runit/runsvdir/"$rlvl" &>/dev/null
        fi
    done
}

add_svc_s6(){
    local mnt="$1" names="$2" rlvl="${3:-default}" error ret
    for svc in $names; do
        error=false
        chroot "$mnt" s6-rc-db -c /etc/s6/rc/compiled type "$svc" &> /dev/null || error=true
        ret="$?"
        if [ $ret -eq 0 ] && [[ "$error" == false ]]; then
            msg2 "Setting [%s]: %s" "${INITSYS}" "$svc"
            chroot "$mnt" s6-rc-bundle-update -c /etc/s6/rc/compiled add "$rlvl" "$svc"
        fi
    done

    # rebuild s6-linux-init binaries
    chroot "$mnt" rm -r /etc/s6/current
    chroot "$mnt" s6-linux-init-maker -1 -N -f /etc/s6/skel -G "/usr/bin/agetty -L -8 tty1 115200" -c /etc/s6/current /etc/s6/current
    chroot "$mnt" mv /etc/s6/current/bin/init /etc/s6/current/bin/s6-init
    chroot "$mnt" cp -a /etc/s6/current/bin /usr
}

#}}}
