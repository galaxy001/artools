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

# }}}
