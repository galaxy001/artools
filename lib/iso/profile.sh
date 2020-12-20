#!/hint/bash

#{{{ profile

show_profile(){
    msg2 "iso_file: %s" "${iso_file}"
    msg2 "AUTOLOGIN: %s" "${AUTOLOGIN}"
    msg2 "HOST_NAME: %s" "${HOST_NAME}"
    msg2 "USER_NAME: %s" "${USER_NAME}"
    msg2 "PASSWORD: %s" "${PASSWORD}"
    msg2 "ADDGROUPS: %s" "${ADDGROUPS}"
    msg2 "SERVICES_LIVE: %s" "${SERVICES_LIVE[*]}"
    msg2 "SERVICES: %s" "${SERVICES[*]}"
}

load_profile(){
    local profile_dir="${DATADIR}/iso-profiles"
    [[ -d ${WORKSPACE_DIR}/iso-profiles ]] && profile_dir=${WORKSPACE_DIR}/iso-profiles

    ROOT_LIST="$profile_dir/${profile}/Packages-Root"
    ROOT_OVERLAY="$profile_dir/${profile}/root-overlay"

    [[ -f "$profile_dir/${profile}/Packages-Live" ]] && LIVE_LIST="$profile_dir/${profile}/Packages-Live"
    [[ -d "$profile_dir/${profile}/live-overlay" ]] && LIVE_OVERLAY="$profile_dir/${profile}/live-overlay"

    [[ -f $profile_dir/${profile}/profile.conf ]] || return 1

    # shellcheck disable=1090
    [[ -r "$profile_dir/${profile}"/profile.conf ]] && . "$profile_dir/${profile}"/profile.conf

    DISPLAYMANAGER=${DISPLAYMANAGER:-'none'}

    AUTOLOGIN=${AUTOLOGIN:-"true"}
    [[ ${DISPLAYMANAGER} == 'none' ]] && AUTOLOGIN="false"

    HOST_NAME=${HOST_NAME:-'artix'}

    USER_NAME=${USER_NAME:-'artix'}

    PASSWORD=${PASSWORD:-'artix'}

    ADDGROUPS=${ADDGROUPS:-"video,power,optical,network,lp,scanner,wheel,users,log"}

    if [[ -z "${SERVICES[*]}" ]];then
        SERVICES=('acpid' 'bluetoothd' 'cronie' 'cupsd' 'syslog-ng' 'connmand')
    fi

    if [[ ${DISPLAYMANAGER} != "none" ]];then
        case "${INITSYS}" in
            'openrc') SERVICES+=('xdm') ;;
            'runit'|'s6') SERVICES+=("${DISPLAYMANAGER}") ;;
        esac
    fi

    SERVICES_LIVE=('artix-live' 'pacman-init')

    return 0
}

load_pkgs(){
    local pkglist="$1" init="$2"
    info "Loading Packages: [%s] ..." "${pkglist##*/}"

    local _init="s|@$init||g" _init_rm1 _init_rm2
    case "$init" in
        'openrc') _init_rm1="s|@runit.*||g"; _init_rm2="s|@s6.*||g" ;;
        's6') _init_rm1="s|@runit.*||g"; _init_rm2="s|@openrc.*||g" ;;
        'runit') _init_rm1="s|@s6.*||g"; _init_rm2="s|@openrc.*||g" ;;
    esac

    local _space="s| ||g" \
        _clean=':a;N;$!ba;s/\n/ /g' \
        _com_rm="s|#.*||g"

    packages=($(sed "$_com_rm" "$pkglist" \
            | sed "$_space" \
            | sed "$_purge" \
            | sed "$_init" \
            | sed "$_init_rm1" \
            | sed "$_init_rm2" \
            | sed "$_clean"))
}

#}}}
