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
    . /usr/lib/os-release
    echo "${HOME_URL}"
}

get_osname(){
    . /usr/lib/os-release
    echo "${NAME}"
}

init_artools_base(){

    ARCH=$(uname -m)

    CHROOTS_DIR=${CHROOTS_DIR:-'/var/lib/artools'}

    WORKSPACE_DIR=${WORKSPACE_DIR:-"/home/${OWNER}/artools-workspace"}

    prepare_dir "${WORKSPACE_DIR}"
}

init_artools_pkg(){

    DOMAIN='artixlinux.org'

    GIT_DOMAIN="gitea.${DOMAIN}"

    GIT_URL="https://${GIT_DOMAIN}"

    GIT_TOKEN=${GIT_TOKEN:-''}

    TREE_DIR_ARTIX=${TREE_DIR_ARTIX:-"${WORKSPACE_DIR}/artixlinux"}

    [[ -z ${TREE_NAMES_ARTIX[@]} ]] && \
    TREE_NAMES_ARTIX=(
            packages
            community
            packages-kernel
            packages-openrc
            packages-runit
            packages-xorg
            packages-python
            packages-perl
            packages-qt5
            packages-devel
            packages-ruby
            packages-gtk
            packages-gnome
            packages-cinnamon
            packages-lxqt
            packages-mate
            packages-kde
    )

    HOST_TREE_ARTIX=${HOST_TREE_ARTIX:-"gitea@${GIT_DOMAIN}:artixlinux"}

    TREE_DIR_ARCH=${TREE_DIR_ARCH:-"${WORKSPACE_DIR}/archlinux"}

    TREE_NAMES_ARCH=(packages community)

    HOST_TREE_ARCH=${HOST_TREE_ARCH:-'git://git.archlinux.org/svntogit'}

    CHROOTS_PKG="${CHROOTS_DIR}/buildpkg"

    REPOS_ROOT=${REPOS_ROOT:-"${WORKSPACE_DIR}/repos"}

    REPOS_MIRROR=${REPOS_MIRROR:-'http://mirror1.artixlinux.org/repos'}

    DBEXT=${DBEXT:-'xz'}

    LINKSDBEXT=${LINKSDBEXT:-"links.tar.${DBEXT}"}

    PKGDBEXT=${PKGDBEXT:-"db.tar.${DBEXT}"}
}

init_artools_iso(){
    CHROOTS_ISO="${CHROOTS_DIR}/buildiso"

    ISO_POOL=${ISO_POOL:-"${WORKSPACE_DIR}/iso"}

    prepare_dir "${ISO_POOL}"

    PROFILE='base'

    ISO_VERSION=${ISO_VERSION:-"$(date +%Y%m%d)"}

    INITSYS=${INITSYS:-'openrc'}

    GPG_KEY=${GPG_KEY:-''}

    UPLIMIT=${UPLIMIT:-1000}

    FILE_HOST="download.${DOMAIN}"

    FILE_HOME=${FILE_HOME:-'/srv/iso'}

    FILE_PORT=${FILE_PORT:-65432}

    ACCOUNT=${ACCOUNT:-'naughtyISOuploader'}
}

load_config(){

    local conf="$1"

    [[ -f "$conf" ]] || return 1

    [[ -r "$conf" ]] && . "$conf"

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

load_user_info(){
    OWNER=${SUDO_USER:-$USER}

    if [[ -n $SUDO_USER ]]; then
        eval "USER_HOME=~$SUDO_USER"
    else
        USER_HOME=$HOME
    fi

    USERCONFDIR="${XDG_CONFIG_HOME:-$USER_HOME/.config}"
    prepare_dir "${USERCONFDIR}"

    USERCACHEDIR="${XDG_CACHE_HOME:-$USER_HOME/.cache}/artools"
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
