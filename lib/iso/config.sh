#!/hint/bash

#{{{ session

configure_hosts(){
    sed -e "s|localhost.localdomain|localhost.localdomain ${HOST_NAME}|" -i "$1"/etc/hosts
}

configure_logind(){
    local conf=$1/etc/elogind/logind.conf
    if [[ -e "$conf" ]];then
        msg2 "Configuring: logind"
        sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' "$conf"
        sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' "$conf"
        sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' "$conf"
    fi
}

configure_services(){
    local mnt="$1"
    add_svc_"${INITSYS}" "$mnt" "${SERVICES[*]} ${SERVICES_LIVE[*]}"
}

configure_system(){
    local mnt="$1"
    configure_logind "$mnt"
    echo "${HOST_NAME}" > "$mnt"/etc/hostname
}

write_live_session_conf(){
    local conf=''
    conf+=$(printf '%s\n' '# live session configuration')
    conf+=$(printf "\nAUTOLOGIN=%s\n" "${AUTOLOGIN}")
    conf+=$(printf "\nUSER_NAME=%s\n" "${USER_NAME}")
    conf+=$(printf "\nPASSWORD=%s\n" "${PASSWORD}")
    conf+=$(printf "\nADDGROUPS='%s'\n" "${ADDGROUPS}")
    printf '%s' "$conf"
}

configure_chroot(){
    local fs="$1"
    msg "Configuring [%s]" "${fs##*/}"
    configure_hosts "$fs"
    configure_system "$fs"
    configure_services "$fs"
    configure_calamares "$fs"
    [[ ! -d "$fs/etc/artools" ]] && mkdir -p "$fs/etc/artools"
    msg2 "Writing: live.conf"
    write_live_session_conf > "$fs/etc/artools/live.conf"
    msg "Done configuring [%s]" "${fs##*/}"
}

#}}}
