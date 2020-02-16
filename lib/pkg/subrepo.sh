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

get_pkg_org(){
    local pkg="$1" org= sub=
    case ${pkg} in
        ruby-*) org="packagesRuby" ;;
        perl-*) org="packagesPerl" ;;
        python-*|python2-*) org="packagesPython" ;;
        *) sub=${pkg:0:1}; org="packages${sub^^}" ;;
    esac
    echo $org
}

subrepo_init() {
    local pkg="$1" org="$2"
    local gitname=$(get_compliant_name "$pkg")
    msg2 "Subrepo init (%s)" "$pkg"
    git subrepo init "$pkg" -r gitea@"${GIT_DOMAIN}":"$org"/"$gitname".git
}

subrepo_push(){
    local pkg="$1"
    msg2 "Subrepo push (%s)" "$pkg"
    git subrepo push "$pkg"
}

subrepo_clean(){
    local pkg="$1"
    msg2 "Subrepo clean (%s)" "$pkg"
    git subrepo clean "$pkg"
}

subrepo_pull(){
    local pkg="$1"
    msg2 "Subrepo pull (%s)" "$pkg"
    git subrepo pull "$pkg"
}

subrepo_clone(){
    local pkg="$1" org="$2"
    local gitname=$(get_compliant_name "$pkg")
    msg2 "Subrepo clone [%s] from (%s)" "$pkg" "$org/$gitname"
    git subrepo clone gitea@"${GIT_DOMAIN}":"$org"/"$gitname".git "$pkg"
}
