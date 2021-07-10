#!/hint/bash

#{{{ iso conf

load_iso_config(){

    local conf="$1/artools-iso.conf"

    [[ -f "$conf" ]] || return 1

    # shellcheck source=/etc/artools/artools-iso.conf
    [[ -r "$conf" ]] && . "$conf"

    ISO_POOL=${ISO_POOL:-"${WORKSPACE_DIR}/iso"}

    ISO_VERSION=${ISO_VERSION:-"$(date +%Y%m%d)"}

    INITSYS=${INITSYS:-'openrc'}

    GPG_KEY=${GPG_KEY:-''}

    COMP_LEVEL=${COMP_LEVEL:-15}

    return 0
}

#}}}

load_iso_config "${USER_CONF_DIR}" || load_iso_config "${SYSCONFDIR}"

prepare_dir "${ISO_POOL}"
