#!/hint/bash

#{{{ iso conf

load_iso_config(){

    local conf="$1/artools-iso.conf"

    [[ -f "$conf" ]] || return 1

    # shellcheck disable=1090
    [[ -r "$conf" ]] && . "$conf"

    CHROOTS_ISO="${CHROOTS_DIR}/buildiso"

    ISO_POOL=${ISO_POOL:-"${WORKSPACE_DIR}/iso"}

    PROFILE='base'

    ISO_VERSION=${ISO_VERSION:-"$(date +%Y%m%d)"}

    INITSYS=${INITSYS:-'openrc'}

    GPG_KEY=${GPG_KEY:-''}

    UPLIMIT=${UPLIMIT:-1000}

    FILE_HOST="download.${DOMAIN}"

    FILE_HOME=${FILE_HOME:-'/srv/iso'}

    FILE_PORT=${FILE_PORT:-65432}

    ACCOUNT=${ACCOUNT:-'naughtyISOuploader'}

    return 0
}

#}}}

load_iso_config "${USER_CONF_DIR}" || load_iso_config "${SYSCONFDIR}"
