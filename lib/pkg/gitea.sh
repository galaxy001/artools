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

get_team_id() {
    local org="$1" team="$2"
    local id=$(curl -s -X GET "${GIT_URL}/api/v1/orgs/$org/teams/search?q=$team&access_token=${GIT_TOKEN}" \
        -H  "accept: application/json" | jq '.data[] .id')
    echo $id
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
