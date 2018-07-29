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
    local pkg="$1"
    git subrepo init $pkg -r gitea@${git_domain}:packages/$pkg.git -b master
}

subrepo_push(){
    local pkg="$1"
    git subrepo push -u "$pkg" -b master
}

subrepo_pull(){
    local pkg="$1" name="${2:-$1}"
    git subrepo pull "$pkg" -b master -r gitea@${git_domain}:packages/$name.git -u
}

subrepo_clone(){
    local pkg="$1" name="${2:-$1}"
    git subrepo clone gitea@gitea.artixlinux.org:packages/$pkg.git "$name" -b master
}
