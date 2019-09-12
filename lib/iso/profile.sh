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

    ROOT_LIST="$profile_dir/${PROFILE}/Packages-Root"
    ROOT_OVERLAY="$profile_dir/${PROFILE}/root-overlay"

    [[ -f "$profile_dir/${PROFILE}/Packages-Live" ]] && LIVE_LIST="$profile_dir/${PROFILE}/Packages-Live"
    [[ -d "$profile_dir/${PROFILE}/live-overlay" ]] && LIVE_OVERLAY="$profile_dir/${PROFILE}/live-overlay"

    [[ -f $profile_dir/${PROFILE}/profile.conf ]] || return 1

    [[ -r $profile_dir/${PROFILE}/profile.conf ]] && . $profile_dir/${PROFILE}/profile.conf

    DISPLAYMANAGER=${DISPLAYMANAGER:-'none'}

    AUTOLOGIN=${AUTOLOGIN:-"true"}
    [[ ${DISPLAYMANAGER} == 'none' ]] && AUTOLOGIN="false"

    HOST_NAME=${HOST_NAME:-'artix'}

    USER_NAME=${USER_NAME:-'artix'}

    PASSWORD=${PASSWORD:-'artix'}

    ADDGROUPS=${ADDGROUPS:-"video,power,optical,network,lp,scanner,wheel,users,log"}

    if [[ -z ${SERVICES[@]} ]];then
        SERVICES=('acpid' 'bluetooth' 'cronie' 'cupsd' 'syslog-ng' 'connman')
    fi

    if [[ ${DISPLAYMANAGER} != "none" ]];then
        case "${INITSYS}" in
            'openrc') SERVICES+=('xdm') ;;
            'runit') SERVICES+=("${DISPLAYMANAGER}") ;;
        esac
    fi

    if [[ -z ${SERVICES_LIVE[@]} ]];then
        SERVICES_LIVE=('artix-live' 'pacman-init')
    fi

    return 0
}

write_live_session_conf(){
    msg2 "Writing live.conf"
    local conf=''
    conf+=$(printf '%s\n' '# live session configuration')
    conf+=$(printf "\nAUTOLOGIN=%s\n" "${AUTOLOGIN}")
    conf+=$(printf "\nUSER_NAME=%s\n" "${USER_NAME}")
    conf+=$(printf "\nPASSWORD=%s\n" "${PASSWORD}")
    conf+=$(printf "\nADDGROUPS='%s'\n" "${ADDGROUPS}")
    printf '%s' "$conf"
}

load_pkgs(){
    local pkglist="$1" init="$2"
    info "Loading Packages: [%s] ..." "${pkglist##*/}"

    local _init="s|@$init||g"
    case "$init" in
        'openrc') _init_rm1="s|@runit.*||g"; _init_rm2="s|@s6*||g" ;;
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
