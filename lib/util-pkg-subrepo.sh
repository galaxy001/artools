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

get_local_head(){
    echo $(git log --pretty=%H ...refs/heads/master^ | head -n 1)
}

get_remote_head(){
    echo $(git ls-remote origin -h refs/heads/master | cut -f1)
}

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

clone_tree(){
    local timer=$(get_timer) url="$1" tree="$2"

    msg "Cloning (%s) ..." "$tree"

    git clone $url/$tree.git
    show_elapsed_time "${FUNCNAME}" "${timer}"
}

has_changes(){
    local head_l="$1" head_r="$2"
    if [[ "$head_l" == "$head_r" ]]; then
        msg2 "remote changes: no"
        return 1
    else
        msg2 "remote changes: yes"
        return 0
    fi
}

pull_tree(){
    local tree="$1"
    local local_head=${2:-$(get_local_head)}
    local remote_head=$(get_remote_head)

    msg "Checking (%s)" "${tree}"
    if $(has_changes "${local_head}" "${remote_head}");then
        git pull origin master
    fi
}

push_tree(){
    local tree="$1"
    msg "Update (%s)" "${tree}"
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

config_tree(){
    local tree="$1"
    cd $tree
        git config --bool pull.rebase true
        git config commit.gpgsign true
        if [[ -n "${GPGKEY}" ]];then
            git config user.signingkey "${GPGKEY}"
        else
            warning "No GPGKEY configured in makepkg.conf!"
        fi
    cd ..
}

subrepo_new(){
    local pkg="$1" team="$2"
    local dest=${TREE_DIR_ARTIX}/$team/$pkg/trunk

    cd ${TREE_DIR_ARTIX}/$team

    local org=$(get_pkg_org "$pkg")

    create_repo "$pkg" "$org"

    add_repo_to_team "$pkg" "$org" "$team"

    subrepo_clone "$pkg" "$org"

    prepare_dir "$dest"

    commit_jenkins_files "$pkg"
}
