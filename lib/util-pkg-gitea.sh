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

create_repo(){
    local pkg="$1" org="$2"
    local gitname=$(get_compliant_name "$pkg")
    local json="{ \"auto_init\": true, \"name\":\"$gitname\", \"gitignores\":\"ArchLinuxPackages\", \"readme\": \"Default\" }"

    msg2 "Create package repo [%s] in org (%s)" "${pkg}" "${org}"

    curl -X POST "${GIT_URL}/api/v1/org/$org/repos?access_token=${GIT_TOKEN}" \
        -H "accept: application/json" \
        -H "content-type: application/json" \
        -d "$json"

    echo
}

delete_repo(){
    local pkg="$1" org="$2"
    local gitname=$(get_compliant_name "$pkg")

    msg2 "Delete package repo [%s] in org (%s)" "${pkg}" "${org}"

    curl -X DELETE "${GIT_URL}/api/v1/repos/$org/$gitname?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json"
}

load_team_id(){
    local org="$1" tree="$2" id=0

    case $org in
        packagesA)
            case $tree in
                packages) id=70 ;;
                community) id=71 ;;
            esac
        ;;
        packagesB)
            case $tree in
                packages) id=72 ;;
                community) id=73 ;;
            esac
        ;;
        packagesC)
            case $tree in
                packages) id=74 ;;
                community) id=75 ;;
            esac
        ;;
        packagesD)
            case $tree in
                packages) id=76 ;;
                community) id=77 ;;
            esac
        ;;
        packagesE)
            case $tree in
                packages) id=78 ;;
                community) id=79 ;;
            esac
        ;;
        packagesF)
            case $tree in
                packages) id=80 ;;
                community) id=81 ;;
            esac
        ;;
        packagesG)
            case $tree in
                packages) id=82 ;;
                community) id=83 ;;
            esac
        ;;
        packagesH)
            case $tree in
                packages) id=84 ;;
                community) id=85 ;;
            esac
        ;;
        packagesI)
            case $tree in
                packages) id=86 ;;
                community) id=87 ;;
            esac
        ;;
        packagesJ)
            case $tree in
                packages) id=88 ;;
                community) id=89 ;;
            esac
        ;;
        packagesK)
            case $tree in
                packages) id=90 ;;
                community) id=91 ;;
            esac
        ;;
        packagesL)
            case $tree in
                packages) id=92 ;;
                community) id=93 ;;
            esac
        ;;
        packagesM)
            case $tree in
                packages) id=94 ;;
                community) id=95 ;;
            esac
        ;;
        packagesN)
            case $tree in
                packages) id=96 ;;
                community) id=97 ;;
            esac
        ;;
        packagesO)
            case $tree in
                packages) id=98 ;;
                community) id=99 ;;
            esac
        ;;
        packagesP)
            case $tree in
                packages) id=100 ;;
                community) id=101 ;;
            esac
        ;;
        packagesQ)
            case $tree in
                packages) id=105 ;;
                community) id=106 ;;
            esac
        ;;
        packagesR)
            case $tree in
                packages) id=107 ;;
                community) id=108 ;;
            esac
        ;;
        packagesS)
            case $tree in
                packages) id=109 ;;
                community) id=110 ;;
            esac
        ;;
        packagesT)
            case $tree in
                packages) id=111 ;;
                community) id=112 ;;
            esac
        ;;
        packagesU)
            case $tree in
                packages) id=113 ;;
                community) id=114 ;;
            esac
        ;;
        packagesV)
            case $tree in
                packages) id=115 ;;
                community) id=116 ;;
            esac
        ;;
        packagesW)
            case $tree in
                packages) id=117 ;;
                community) id=118 ;;
            esac
        ;;
        packagesX)
            case $tree in
                packages) id=119 ;;
                community) id=120 ;;
            esac
        ;;
        packagesY)
            case $tree in
                packages) id=121 ;;
                community) id=122 ;;
            esac
        ;;
        packagesZ)
            case $tree in
                packages) id=123 ;;
                community) id=124 ;;
            esac
        ;;
        packagesPython)
            case $tree in
                packages) id=103 ;;
                community) id=104 ;;
            esac
        ;;
        packagesPerl)
            case $tree in
                packages) id=102 ;;
                community) id=125 ;;
            esac
        ;;
    esac
    echo $id
}

add_repo_to_team(){
    local pkg="$1" org="$2" tree="$3"
    local id=$(load_team_id "$org" "$tree")

    msg2 "Adding package repo [%s] to team (%s)" "$pkg" "$tree"

    curl -X PUT "${GIT_URL}/api/v1/teams/$id/repos/$org/$pkg?access_token=${GIT_TOKEN}" \
        -H  "accept: application/json"
}
