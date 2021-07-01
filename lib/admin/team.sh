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

# list_teams() {
#     local org="$1"
#     local url
#
#     url="${GIT_URL}/api/v1/orgs/$org/teams?access_token=${GIT_TOKEN}"
#
#     api_get "$url" -H  "accept: application/json"
# }
#
# get_team_id() {
#     local org="$1" team="$2"
#     local id url
#
#     url="${GIT_URL}/api/v1/orgs/$org/teams/search?q=$team&access_token=${GIT_TOKEN}"
#
#     id=$(api_get "$url" -H  "accept: application/json" | jq '.data[] .id')
#     echo "$id"
# }
#
# list_repos() {
#     curl -X GET "https://gitea.artixlinux.org/api/v1/orgs/packagesA/repos" -H  "accept: application/json"
# }
#
# update_team() {
#     local id="$1"
#     local perm="$2"
#     local name="$3"
#     local url json
#
#     url="${GIT_URL}/api/v1/teams/$id?access_token=${GIT_TOKEN}"
#
#     json="{  \"can_create_org_repo\": true,  \"description\": \"string\",  \"includes_all_repositories\": false,  \"name\": \"$name\",  \"permission\": \"$perm\",  \"units\": [    \"repo.code\",    \"repo.issues\",    \"repo.ext_issues\",    \"repo.wiki\",    \"repo.pulls\",    \"repo.releases\",    \"repo.projects\",    \"repo.ext_wiki\"  ]}"
#
#     api_patch "$url" -H  "accept: application/json" \
#                     -H  "Content-Type: application/json" \
#                     -d "$json"
# }

# }}}
