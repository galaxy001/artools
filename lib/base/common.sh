#!/hint/bash

#{{{ common

prepare_dir(){
    [[ ! -d $1 ]] && mkdir -p "$1"
}

get_osname(){
    # shellcheck disable=1091
    . /usr/lib/os-release
    echo "${NAME}"
}

if [[ -n $SUDO_USER ]]; then
    eval "USER_HOME=~$SUDO_USER"
else
    USER_HOME=$HOME
fi

USER_CONF_DIR="${XDG_CONFIG_HOME:-$USER_HOME/.config}/artools"

get_makepkg_conf() {
    makepkg_conf="${DATADIR}/makepkg.conf"
    [[ -f ${USER_CONF_DIR}/makepkg.conf ]] && makepkg_conf="${USER_CONF_DIR}/makepkg.conf"
}

get_pacman_conf() {
    local repo="$1"
    pacman_conf="${DATADIR}/pacman-${repo}.conf"
    [[ -f "${USER_CONF_DIR}/pacman-${repo}.conf" ]] && pacman_conf="${USER_CONF_DIR}/pacman-${repo}.conf"
}

prepare_artools(){
    prepare_dir "${WORKSPACE_DIR}"
    prepare_dir "${USER_CONF_DIR}"
}

#}}}
