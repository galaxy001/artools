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
    msg2 "Update (%s)" "$pkg"
    git subrepo push "$pkg"
}

subrepo_config(){
    local pkg="$1" org="$2"
    local gitname=$(get_compliant_name "$pkg")
    local url=gitea@"${GIT_DOMAIN}":"$org"/"$gitname".git
    msg2 "Update .gitrepo (%s) [%s]" "$pkg" "$url"
    git subrepo config "$pkg" remote "$url"
}

subrepo_clean(){
    local pkg="$1"
    msg2 "Clean (%s)" "$pkg"
    git subrepo clean "$pkg"
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

mainrepo_pull(){
    local tree="$1"
    msg2 "Check (%s)" "${tree}"
    git push origin master
}


mainrepo_push(){
    local tree="$1"
    msg2 "Update (%s)" "${tree}"
    git push origin master
}

write_jenkinsfile(){
    local pkg="$1"
    local jenkins=$pkg/Jenkinsfile

    echo "@Library('artix-ci') import org.artixlinux.RepoPackage" > $jenkins
    echo '' >> $jenkins
    echo 'PackagePipeline(new RepoPackage(this))' >> $jenkins
    echo '' >> $jenkins

    git add $jenkins
}

write_agentyaml(){
    local pkg="$1"
    local agent=$pkg/.artixlinux/agent.yaml label='master'
    [[ -d $pkg/.artixlinux ]] || mkdir $pkg/.artixlinux

    echo '%YAML 1.2' > $agent
    echo '---' >> $agent
    echo '' >> $agent
    echo "label: $label" >> $agent
    echo '' >> $agent

    git add $agent
}

commit_jenkins_files(){
    local pkg="$1"

    write_jenkinsfile "$pkg"
    write_agentyaml "$pkg"

    git commit -m "add jenkinsfile & .artixlinux/agent.yaml"
}
