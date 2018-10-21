#!/bin/bash
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

get_compliant_name(){
    local gitname="$1"
    case $gitname in
        *+) gitname=${gitname//+/plus}
    esac
    echo $gitname
}


create_repo(){
    local pkg="$1"
    local gitname=$(get_compliant_name "$pkg")
    curl -X POST "${GIT_URL}/api/v1/org/packages/repos?access_token=${GIT_TOKEN}" -H "accept: application/json" -H "content-type: application/json" -d "{ \"auto_init\": true, \"name\":\"$gitname\", \"readme\": \"Default\" }"
}

delete_repo(){
    local pkg="$1"
    local gitname=$(get_compliant_name "$pkg")
    curl -X DELETE "${GIT_URL}/api/v1/repos/packages/$gitname?access_token=${GIT_TOKEN}" -H  "accept: application/json"
}

find_team(){
    local pkg="$1" team_id=

    if [[ -f $pkg/repos/core-x86_64/PKGBUILD ]];then
        team_id=18
    elif [[ -f $pkg/repos/core-any/PKGBUILD ]];then
        team_id=18
    elif [[ -f $pkg/repos/extra-x86_64/PKGBUILD ]];then
        team_id=19
    elif [[ -f $pkg/repos/extra-any/PKGBUILD ]];then
        team_id=19
    elif [[ -f $pkg/repos/community-x86_64/PKGBUILD ]];then
        team_id=20
    elif [[ -f $pkg/repos/community-any/PKGBUILD ]];then
        team_id=20
    elif [[ -f $pkg/repos/multilib-x86_64/PKGBUILD ]];then
        team_id=21
    fi
    echo $team_id
}

add_repo_to_team(){
    local pkg="$1" path="$2"
    local id=$(find_team "$path")

    curl -X PUT "${GIT_URL}/api/v1/teams/$id/repos/packages/$pkg?access_token=${GIT_TOKEN}" -H  "accept: application/json"
}
