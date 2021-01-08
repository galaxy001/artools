#!/hint/bash

#{{{ session

configure_services(){
    local mnt="$1"
    add_svc_"${INITSYS}" "$mnt" "${SERVICES[*]}"
}


write_live_session_conf(){
    local conf=''
    conf+=$(printf '%s\n' '# live session configuration')
    conf+=$(printf "\nAUTOLOGIN=%s\n" "${AUTOLOGIN}")
    conf+=$(printf "\nPASSWORD=%s\n" "${PASSWORD}")
    printf '%s' "$conf"
}

configure_chroot(){
    local fs="$1"
    msg "Configuring [%s]" "${fs##*/}"
    configure_services "$fs"
    configure_calamares "$fs"
    [[ ! -d "$fs/etc/artools" ]] && mkdir -p "$fs/etc/artools"
    msg2 "Writing: live.conf"
    write_live_session_conf > "$fs/etc/artools/live.conf"
    msg "Done configuring [%s]" "${fs##*/}"
}

#}}}
