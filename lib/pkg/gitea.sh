#!/hint/bash

#{{{ gitea api

api_put() {
    curl -s -X PUT "$@"
}

api_delete() {
    curl -s -X DELETE "$@"
}

api_post() {
    curl -s -X POST "$@"
}

create_repo() {
    local pkg="$1"
    local org="$2"
    local gitname json url
    gitname=$(get_compliant_name "$pkg")

    json="{ \"auto_init\": true, \"name\":\"$gitname\", \"gitignores\":\"ArchLinuxPackages\", \"readme\": \"Default\" }"

    url="${GIT_URL}/api/v1/org/$org/repos?access_token=${GIT_TOKEN}"

    msg2 "Create package repo [%s] in org (%s)" "${pkg}" "${org}"

    api_post "$url" -H "accept: application/json" \
                    -H "content-type: application/json" \
                    -d "$json"
}

transfer_repo() {
    local pkg="$1"
    local old_owner="$2"
    local new_owner="landfill" json url
    local gitname=$(get_compliant_name "$pkg")

    json="{  \"new_owner\": \"$new_owner\",  \"team_ids\": []}"

    url="${GIT_URL}/api/v1/repos/$old_owner/$gitname/transfer?access_token=${GIT_TOKEN}"

    msg2 "Transfer package repo [%s] in org (%s)" "${pkg}" "$new_owner"

    api_post "$url" -H  "accept: application/json" \
                    -H  "Content-Type: application/json" \
                    -d "$json"
}

add_team_to_repo() {
    local pkg="$1"
    local org="$2"
    local team="$3"
    local gitname url
    gitname=$(get_compliant_name "$pkg")

    url="${GIT_URL}/api/v1/repos/$org/$gitname/teams/$team?access_token=${GIT_TOKEN}"

    msg2 "Adding team (%s) to package repo [%s]" "$team" "$gitname"

    api_put "$url" -H  "accept: application/json"
}

remove_team_from_repo() {
    local pkg="$1"
    local org="$2"
    local team="$3"
    local gitname url
    gitname=$(get_compliant_name "$pkg")

    url="${GIT_URL}/api/v1/repos/$org/$gitname/teams/$team?access_token=${GIT_TOKEN}"

    msg2 "Removing team (%s) from package repo [%s]" "$gitname" "$team"

    api_delete "$url" -H  "accept: application/json"
}

#}}}
