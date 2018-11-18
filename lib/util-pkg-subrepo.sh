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

subrepo_init(){
    local pkg="$1" branch=master org=packages
    git subrepo init "$pkg" -r gitea@"${GIT_DOMAIN}":"$org"/"$pkg".git -b "$branch"
}

subrepo_push(){
    local pkg="$1" branch=master
    git subrepo push "$pkg" -u -b "$branch" --clean
}

subrepo_pull(){
    local pkg="$1" name="${2:-$1}" branch=master org=packages
    git subrepo pull "$pkg" -r gitea@"${GIT_DOMAIN}":"$org"/"$name".git -u -b "$branch" #--clean
}

subrepo_clone(){
    local pkg="$1" name="${2:-$1}" branch=master org=packages
    git subrepo clone gitea@"${GIT_DOMAIN}":"$org"/"$name".git "$pkg" -b "$branch"
}
