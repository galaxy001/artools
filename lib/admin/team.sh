#!/hint/bash

# {{{ team api

search_team() {
    local org="$1"
    local team="$2"
    local url id

    url="${GIT_URL}/api/v1/orgs/$org/teams/search?q=$team&include_desc=false&access_token=${GIT_TOKEN}"

    id=$(api_get "$url" -H  "accept: application/json" | jq '.data[] .id')

    echo "$id"
}

add_user_to_team() {
    local user="$1"
    local id="$2"
    local url

    url="${GIT_URL}/api/v1/teams/$id/members/$user?access_token=${GIT_TOKEN}"

    api_put "$url" -H  "accept: application/json"
}

remove_user_from_team() {
    local user="$1"
    local id="$2"
    local url

    url="${GIT_URL}/api/v1/teams/$id/members/$user?access_token=${GIT_TOKEN}"

    api_delete "$url" -H  "accept: application/json"
}

has_team() {
    local org="$1"
    local repo="$2"
    local team="$3"
    local url match

    url="${GIT_URL}/api/v1/repos/$org/$repo/teams/$team?access_token=${GIT_TOKEN}"
    match=$(api_get "$url" -H  "accept: application/json" | jq '.name')

    msg "repo [%s] team query ..." "$repo"

    if [[ "$match" != null ]]; then
        msg2 "result: %s" "$match"
        return 0
    fi
    return 1
}

list_org_repos() {
    local org="$1"
    local url repos

    url="${GIT_URL}/api/v1/orgs/packagesA/repos?access_token=${GIT_TOKEN}"

    repos=$(curl -X GET "$url" -H  "accept: application/json" | jq '.[] .name' | tr -d \")

    echo "$repos"
}

list_repo_teams() {
    local org="$1"
    local repo="$2"
    local team="$3"
    local url teams

    url="${GIT_URL}/api/v1/repos/$org/$repo/teams?access_token=${GIT_TOKEN}"

    msg "repo [%s] team query ..." "$repo"
    msg2 "assigned: %s" "$team"
    teams=($(api_get "$url" -H  "accept: application/json" | jq '.[] .name' | tr -d \"))

    if (( ${#teams[@]} < 2 )); then
        warning "repo [%s] has no team assigned! Should be (%s)" "$repo"  "$team"
        "${add}" && add_team_to_repo "$repo" "$org" "$team"

    elif (( ${#teams[@]} > 2 )); then
        for t in "${teams[@]}"; do
            if [[ "$t" != $team ]]; then
                if [[ "$t" != Owners ]]; then
                    warning "repo [%s] has wrong team (%s) assigned!" "$repo" "$t"
                    "${remove}" && remove_team_from_repo "$repo" "$org" "$t"
                fi
            fi
        done
    fi
}

# }}}
