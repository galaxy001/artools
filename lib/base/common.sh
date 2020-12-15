#!/hint/bash

#{{{ common

get_makepkg_conf() {
    makepkg_conf="${DATADIR}/makepkg.conf"
    [[ -f ${USER_CONF_DIR}/makepkg.conf ]] && makepkg_conf="${USER_CONF_DIR}/makepkg.conf"
}

get_pacman_conf() {
    local repo="$1"
    pacman_conf="${DATADIR}/pacman-${repo}.conf"
    [[ -f "${USER_CONF_DIR}/pacman-${repo}.conf" ]] && pacman_conf="${USER_CONF_DIR}/pacman-${repo}.conf"
}

#}}}
