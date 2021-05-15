#!/hint/bash

#{{{ git

get_local_head(){
    git log --pretty=%H ...refs/heads/master^ | head -n 1
}

get_remote_head(){
    git ls-remote origin -h refs/heads/master | cut -f1
}

has_changeset(){
    local head_l="$1" head_r="$2"
    if [[ "$head_l" == "$head_r" ]]; then
        msg2 "remote changes: no"
        return 1
    else
        msg2 "remote changes: yes"
        return 0
    fi
}

pull_tree(){
    local tree="$1" local_head="$2" os="${3:-Artix}"
    local remote_head
    remote_head=$(get_remote_head)

    msg "Checking (%s) (%s)" "${tree}" "$os"
    if has_changeset "${local_head}" "${remote_head}";then
        git pull origin master
    fi
}

#}}}
