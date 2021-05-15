#!/hint/bash

#{{{ gitea api

add_team_to_repo() {
    local name="$1"
    local org="$2"
    local team="$3"
    local url

    url="${GIT_URL}/api/v1/repos/$org/$name/teams/$team?access_token=${GIT_TOKEN}"

    msg2 "Adding team (%s) to package repo [%s]" "$team" "$name"

    api_put "$url" -H  "accept: application/json"
}

remove_team_from_repo() {
    local name="$1"
    local org="$2"
    local team="$3"
    local url

    url="${GIT_URL}/api/v1/repos/$org/$name/teams/$team?access_token=${GIT_TOKEN}"

    msg2 "Removing team (%s) from package repo [%s]" "$team" "$name"

    api_delete "$url" -H  "accept: application/json"
}

#}}}
