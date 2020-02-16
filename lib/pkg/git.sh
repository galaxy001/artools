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

get_local_head(){
    echo $(git log --pretty=%H ...refs/heads/master^ | head -n 1)
}

get_remote_head(){
    echo $(git ls-remote origin -h refs/heads/master | cut -f1)
}

clone_tree(){
    local timer=$(get_timer) url="$1" tree="$2" os="${3:-$(get_osname)}"

    msg "Cloning %s (%s) ..." "$tree" "$os"

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
    local tree="$1" local_head="$2" os="${3:-$(get_osname)}"
    local remote_head=$(get_remote_head)

    msg "Checking (%s) (%s)" "${tree}" "$os"
    if has_changes "${local_head}" "${remote_head}";then
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

    git commit -m "initial commit"
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

# write_gitignore() {
#     local pkg="$1"
#     local gitignore=$pkg/.gitignore
#     echo '# ---> ArchLinuxPackages' > $gitignore
#     echo '*.tar' >> $gitignore
#     echo '*.tar.*' >> $gitignore
#     echo '*.jar' >> $gitignore
#     echo '*.exe' >> $gitignore
#     echo '*.msi' >> $gitignore
#     echo '*.zip' >> $gitignore
#     echo '*.tgz' >> $gitignore
#     echo '*.log' >> $gitignore
#     echo '*.log.*' >> $gitignore
#     echo '*.sig' >> $gitignore
#     echo '' >> $gitignore
#     echo 'pkg/' >> $gitignore
#     echo 'src/' >> $gitignore
#     echo '' >> $gitignore
#     echo '# ---> Archives' >> $gitignore
#     echo '*.7z' >> $gitignore
#     echo '*.rar' >> $gitignore
#     echo '*.gz' >> $gitignore
#     echo '*.bzip' >> $gitignore
#     echo '*.bz2' >> $gitignore
#     echo '*.xz' >> $gitignore
#     echo '*.lzma' >> $gitignore
#     echo '*.cab' >> $gitignore
#     echo '' >> $gitignore
#     echo '# ---> systemd' >> $gitignore
#     echo '*.service' >> $gitignore
#     echo '*.socket' >> $gitignore
#     echo '*.timer' >> $gitignore
#     echo '' >> $gitignore
#     echo '# ---> snap' >> $gitignore
#     echo '*.snap' >> $gitignore
#     echo '' >> $gitignore
#
#     git add $gitignore
# }
#
# write_readme(){
#     local pkg="$1"
#     local readme=$pkg/README.md
#
#     echo "# $pkg" > $readme
#     echo '' >> $readme
#
#     git add $readme
# }
#
# subrepo_new2(){
#     local group="${1:-$GROUP}" team="${2:-$TEAM}"
#     local dest=${TREE_DIR_ARTIX}/$group/${PACKAGE}/trunk
#
#     cd ${TREE_DIR_ARTIX}/$group
#
#     local org=$(get_pkg_org "${PACKAGE}")
#
#     prepare_dir "$dest"
#
#     subrepo_init "${PACKAGE}" "$org"
#
#     commit_jenkins_files2 "${PACKAGE}"
#
#     subrepo_push "${PACKAGE}"
#
#     add_repo_to_team "${PACKAGE}" "$org" "$team"
# }
#
# commit_jenkins_files2(){
#     local pkg="$1"
#
#     write_jenkinsfile "$pkg"
#     write_agentyaml "$pkg"
#     write_readme "$pkg"
#     write_gitignore "$pkg"
#
#     git commit -m "initial commit"
# }
