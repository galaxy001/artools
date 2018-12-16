#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

get_timer(){
    echo $(date +%s)
}

# $1: start timer
elapsed_time(){
    echo $(echo $1 $(get_timer) | awk '{ printf "%0.2f",($2-$1)/60 }')
}

show_elapsed_time(){
    info "Time %s: %s minutes" "$1" "$(elapsed_time $2)"
}

load_vars() {
    local var

    [[ -f $1 ]] || return 1

    for var in {SRC,SRCPKG,PKG,LOG}DEST MAKEFLAGS PACKAGER CARCH GPGKEY; do
        [[ -z ${!var:-} ]] && eval "$(grep -a "^${var}=" "$1")"
    done

    return 0
}

prepare_dir(){
    [[ ! -d $1 ]] && mkdir -p $1
}

get_disturl(){
    source /usr/lib/os-release
    echo "${HOME_URL}"
}

get_osname(){
    source /usr/lib/os-release
    echo "${NAME}"
}

init_artools_base(){

    ARCH=$(uname -m)

    [[ -z ${CHROOTS_DIR} ]] && CHROOTS_DIR='/var/lib/artools'

    [[ -z ${WORKSPACE_DIR} ]] && WORKSPACE_DIR=/home/${OWNER}/artools-workspace

    prepare_dir "${WORKSPACE_DIR}"
}

init_artools_pkg(){

    DOMAIN='artixlinux.org'

    GIT_DOMAIN="gitea.${DOMAIN}"

    GIT_URL="https://${GIT_DOMAIN}"

    [[ -z ${GIT_TOKEN} ]] && GIT_TOKEN=''

    [[ -z ${TREE_DIR_ARTIX} ]] && TREE_DIR_ARTIX="${WORKSPACE_DIR}/artixlinux"

    [[ -z ${HOST_TREE_ARTIX} ]] && HOST_TREE_ARTIX="gitea@${GIT_DOMAIN}:artixlinux"

    [[ -z ${TREE_DIR_ARCH} ]] && TREE_DIR_ARCH="${WORKSPACE_DIR}/archlinux"

    [[ -z ${HOST_TREE_ARCH} ]] && HOST_TREE_ARCH='git://projects.archlinux.org/svntogit'

    CHROOTS_PKG="${CHROOTS_DIR}/buildpkg"

    [[ -z ${REPOS_ROOT} ]] && REPOS_ROOT="${WORKSPACE_DIR}/repos"
}

init_artools_iso(){
    CHROOTS_ISO="${CHROOTS_DIR}/buildiso"

    [[ -z ${ISO_POOL} ]] && ISO_POOL="${WORKSPACE_DIR}/iso"

    prepare_dir "${ISO_POOL}"

    PROFILE='base'

    [[ -z ${ISO_VERSION} ]] && ISO_VERSION=$(date +%Y%m%d)

    [[ -z ${INITSYS} ]] && INITSYS="openrc"

    [[ -z ${GPG_KEY} ]] && GPG_KEY=''

    [[ -z ${UPLIMIT} ]] && UPLIMIT=1000

    FILE_HOST="download.${DOMAIN}"

    [[ -z ${FILE_HOME} ]] && FILE_HOME="/srv/iso"

    [[ -z ${FILE_PORT} ]] && FILE_PORT=65432

    [[ -z ${ACCOUNT} ]] && ACCOUNT="naughtyISOuploader"
}


load_config(){

    [[ -f $1 ]] || return 1

    ARTOOLS_CONF="$1"

    [[ -r ${ARTOOLS_CONF} ]] && source ${ARTOOLS_CONF}

    init_artools_base

    init_artools_pkg

    init_artools_iso

    return 0
}

user_own(){
    local flag=$2
    chown ${flag} "${OWNER}:$(id --group ${OWNER})" "$1"
}

user_run(){
    su ${OWNER} -c "$@"
}

clean_dir(){
    if [[ -d $1 ]]; then
        msg "Cleaning [%s] ..." "$1"
        rm -r $1/*
    fi
}

load_user_info(){
    OWNER=${SUDO_USER:-$USER}

    if [[ -n $SUDO_USER ]]; then
        eval "USER_HOME=~$SUDO_USER"
    else
        USER_HOME=$HOME
    fi

    AT_USERCONFDIR="${XDG_CONFIG_HOME:-$USER_HOME/.config}/artools"
    PAC_USERCONFDIR="${XDG_CONFIG_HOME:-$USER_HOME/.config}/pacman"
    prepare_dir "${AT_USERCONFDIR}"
}

# orig_argv=("$0" "$@")
check_root() {
    local keepenv=$1

    (( EUID == 0 )) && return
    if type -P sudo >/dev/null; then
        exec sudo --preserve-env=$keepenv -- "${orig_argv[@]}"
    else
        exec su root -c "$(printf ' %q' "${orig_argv[@]}")"
    fi
}
