#!/hint/bash

#{{{ base conf

CHROOTVERSION=0.10

DATADIR=${DATADIR:-'@datadir@/artools'}
SYSCONFDIR=${SYSCONFDIR:-'@sysconfdir@/artools'}

load_base_config(){

    local conf="$1/artools-base.conf"

    [[ -f "$conf" ]] || return 1

    # shellcheck disable=1090
    [[ -r "$conf" ]] && . "$conf"

    ARCH=$(uname -m)

    CHROOTS_DIR=${CHROOTS_DIR:-'/var/lib/artools'}

    WORKSPACE_DIR=${WORKSPACE_DIR:-"/home/${USER}/artools-workspace"}

    return 0
}

#}}}

load_base_config "${USER_CONF_DIR}" || load_base_config "${SYSCONFDIR}"
