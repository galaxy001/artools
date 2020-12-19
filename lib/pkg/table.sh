#!/hint/bash

#{{{ table

msg_table_header(){
    local mesg=$1; shift
    # shellcheck disable=2059
    printf "${BLUE} ${mesg} ${ALL_OFF}\n" "$@" >&2
}

msg_row_downgrade(){
    local mesg=$1; shift
    # shellcheck disable=2059
    printf "${YELLOW} ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg_row_notify(){
    local mesg=$1; shift
    # shellcheck disable=2059
    printf "${GREEN} ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg_row(){
    local mesg=$1; shift
#     printf "${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
    # shellcheck disable=2059
    printf "${WHITE} ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg_row_upgrade(){
    local mesg=$1; shift
    # shellcheck disable=2059
    printf "${RED} ${mesg} ${ALL_OFF}\n" "$@" >&2
}

#}}}
