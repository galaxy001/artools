#!/hint/bash

add_user_to_team() {
    local user="$1"
    local id="$2"
    local url

    url="${GIT_URL}/api/v1/teams/$id/members/$user?access_token=${GIT_TOKEN}"

    curl -X PUT "$url" -H  "accept: application/json"
}

remove_user_from_team() {
    local user="$1"
    local id="$2"
    local url

    url="${GIT_URL}/api/v1/teams/$id/members/$user?access_token=${GIT_TOKEN}"

    curl -X DELETE "$url" -H  "accept: application/json"
}

list_teams() {
    local org="$1"
    local url

    url="${GIT_URL}/api/v1/orgs/$org/teams?access_token=${GIT_TOKEN}"

    curl -X GET "$url" -H  "accept: application/json"
}
