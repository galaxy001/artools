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

subrepo_push(){
    local pkg="$1"
    git subrepo push "$pkg" --clean
}

subrepo_pull(){
    local pkg="$1"
    git subrepo pull "$pkg"
}

subrepo_clone(){
    local pkg="$1" org="$2"
    local gitname=$(get_compliant_name "$pkg")
    msg2 "Getting package repo [%s] from org (%s)" "$pkg" "$org/$gitname"
    git subrepo clone gitea@"${GIT_DOMAIN}":"$org"/"$gitname".git "$pkg"
}

write_jenkinsfile(){
    local jenkins=Jenkinsfile
    echo "@Library('artix-ci') import org.artixlinux.RepoPackage" > $jenkins
    echo '' >> $jenkins
    echo 'PackagePipeline(new RepoPackage(this))' >> $jenkins
    echo '' >> $jenkins
}

write_agentyaml(){
    local agent=.artixlinux/agent.yaml label='master'
    [[ -d .artixlinux ]] || mkdir .artixlinux
    echo '%YAML 1.2' > $agent
    echo '---' >> $agent
    echo '' >> $agent
    echo "label: $label" >> $agent
    echo '' >> $agent
}

commit_jenkins_files(){
    write_jenkinsfile
    write_agentyaml
    git add Jenkinsfile
    git add .artixlinux
    git commit -m "add jenkinsfile & .artixlinux/agent.yaml"
}
