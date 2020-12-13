#!/hint/bash

#{{{ base conf

CHROOTVERSION=0.10

DATADIR=${DATADIR:-'@datadir@/artools'}
SYSCONFDIR=${SYSCONFDIR:-'@sysconfdir@/artools'}

if [[ -n $SUDO_USER ]]; then
    eval "USER_HOME=~$SUDO_USER"
else
    USER_HOME=$HOME
fi

USER_CONF_DIR="${XDG_CONFIG_HOME:-$USER_HOME/.config}/artools"



load_base_config(){

    local conf="$1/artools-base.conf"

    [[ -f "$conf" ]] || return 1

    # shellcheck disable=1090
    [[ -r "$conf" ]] && . "$conf"

    ARCH=$(uname -m)

    DOMAIN='artixlinux.org'

    CHROOTS_DIR=${CHROOTS_DIR:-'/var/lib/artools'}

    WORKSPACE_DIR=${WORKSPACE_DIR:-"/home/${USER}/artools-workspace"}

    return 0
}

#}}}

load_base_config "${USER_CONF_DIR}" || load_base_config "${SYSCONFDIR}"

prepare_dir "${WORKSPACE_DIR}"
prepare_dir "${USER_CONF_DIR}"
