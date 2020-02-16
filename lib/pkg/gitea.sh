#!/bin/bash
#
# Copyright (C) 2018-19 artoo@artixlinux.org
# Copyright (C) 2018 Artix Linux Developers
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

create_repo() {
    local pkg="$1" org="$2"
    local gitname=$(get_compliant_name "$pkg")
    local json="{ \"auto_init\": true, \"name\":\"$gitname\", \"gitignores\":\"ArchLinuxPackages\", \"readme\": \"Default\" }"

    msg2 "Create package repo [%s] in org (%s)" "${pkg}" "${org}"

    curl -s -X POST "${GIT_URL}/api/v1/org/$org/repos?access_token=${GIT_TOKEN}" \
        -H "accept: application/json" \
        -H "content-type: application/json" \
        -d "$json"

    echo
}

delete_repo() {
    local pkg="$1" org="$2"
    local gitname=$(get_compliant_name "$pkg")

    msg2 "Delete package repo [%s] in org (%s)" "${pkg}" "${org}"

    curl -s -X DELETE "${GIT_URL}/api/v1/repos/$org/$gitname?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json"
}

get_team_id() {
    local org="$1" team="$2"
    local id=$(curl -s -X GET "${GIT_URL}/api/v1/orgs/$org/teams/search?q=$team&access_token=${GIT_TOKEN}" \
        -H  "accept: application/json" | jq '.data[] .id')
    echo $id
}

list_team_repos() {
    local id="$1"
    local result=$(curl -X GET "${GIT_URL}/api/v1/teams/$id/repos?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json" | jq '.[]' | jq -r '.name')
    echo ${result[@]}
}

add_repo_to_team() {
    local pkg="$1" org="$2" team="$3"
    local id=$(get_team_id "$org" "$team")
    local gitname=$(get_compliant_name "$pkg")

    msg2 "Adding package repo [%s] to team (%s)" "$gitname" "$team"

    curl -s -X PUT "${GIT_URL}/api/v1/teams/$id/repos/$org/$gitname?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json"
}

remove_repo_from_team() {
    local pkg="$1" org="$2" team="$3"
    local id=$(get_team_id "$org" "$team")
    local gitname=$(get_compliant_name "$pkg")

    msg2 "Removing package repo [%s] from team (%s)" "$gitname" "$team"

    curl -s -X DELETE "${GIT_URL}/api/v1/teams/$id/repos/$org/$gitname?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json"
}

add_user_to_team() {
    local org="$1" team="$2" user="$3"
    local id=$(get_team_id "$org" "$team")

    msg2 "Adding [%s] to team (%s) in org (%s)" "$user" "$team" "$org"

    curl -X PUT "${GIT_URL}/api/v1/teams/$id/members/$user?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json"
}

remove_user_from_team() {
    local org="$1" team="$2" user="$3"
    local id=$(get_team_id "$org" "$team")

    msg2 "Removing [%s] from team (%s) in org (%s)" "$user" "$team" "$org"

    curl -X DELETE "${GIT_URL}/api/v1/teams/$id/members/$user?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json"
}

create_team() {
    local org="$1" name="$2"
    local json="{  \"can_create_org_repo\": true,  \"description\": \"\",  \"includes_all_repositories\": false,  \"name\": \"$name\",  \"permission\": \"write\",  \"units\": [    \"repo.code\",    \"repo.issues\",    \"repo.ext_issues\",    \"repo.wiki\",    \"repo.pulls\",    \"repo.releases\",    \"repo.ext_wiki\"  ]}"

    curl -X POST "${GIT_URL}/api/v1/orgs/$org/teams?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json" \
        -H  "Content-Type: application/json" \
        -d "$json"
}

delete_team() {
    local org="$1" team="$2"
    local id=$(get_team_id "$org" "$team")
    curl -X DELETE "${GIT_URL}/api/v1/teams/$id?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json"
}
