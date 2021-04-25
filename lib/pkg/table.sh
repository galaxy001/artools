#!/hint/bash

#{{{ table

msg_table_header(){
    local mesg=$1; shift
    # shellcheck disable=2059
    printf "${BLUE} ${mesg} ${ALL_OFF}\n" "$@" >&2
}

msg_row_yellow(){
    local mesg=$1; shift
    # shellcheck disable=2059
    printf "${YELLOW} ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg_row_green(){
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

msg_row_red(){
    local mesg=$1; shift
    # shellcheck disable=2059
    printf "${RED} ${mesg} ${ALL_OFF}\n" "$@" >&2
}

#}}}
