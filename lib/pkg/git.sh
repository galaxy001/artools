#!/hint/bash

#{{{ git

get_compliant_name(){
    local gitname="$1"
    case "$gitname" in
        *+) gitname=${gitname//+/plus}
    esac
    echo "$gitname"
}

get_pkg_org(){
    local pkg="$1" org sub
    case ${pkg} in
        ruby-*) org="packagesRuby" ;;
        perl-*) org="packagesPerl" ;;
        python-*|python2-*) org="packagesPython" ;;
        *) sub=${pkg:0:1}; org="packages${sub^^}" ;;
    esac
    echo "$org"
}

get_team_id() {
    local org="$1" team="$2"
    local id
    id=$(curl -s -X GET "${GIT_URL}/api/v1/orgs/$org/teams/search?q=$team&access_token=${GIT_TOKEN}" \
        -H  "accept: application/json" | jq '.data[] .id')
    echo "$id"
}

add_repo_to_team() {
    local pkg="$1" org="$2" team="$3"
    local id
    id=$(get_team_id "$org" "$team")
    local gitname
    gitname=$(get_compliant_name "$pkg")

    msg2 "Adding package repo [%s] to team (%s)" "$gitname" "$team"

    curl -s -X PUT "${GIT_URL}/api/v1/teams/$id/repos/$org/$gitname?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json"
}

remove_repo_from_team() {
    local pkg="$1" org="$2" team="$3"
    local id
    id=$(get_team_id "$org" "$team")
    local gitname
    gitname=$(get_compliant_name "$pkg")

    msg2 "Removing package repo [%s] from team (%s)" "$gitname" "$team"

    curl -s -X DELETE "${GIT_URL}/api/v1/teams/$id/repos/$org/$gitname?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json"
}

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
