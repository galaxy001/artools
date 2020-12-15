#!/hint/bash

#{{{ jenkins

write_jenkinsfile(){
    local pkg="$1"
    local jenkins=$pkg/Jenkinsfile

    echo "@Library('artix-ci') import org.artixlinux.RepoPackage" > "$jenkins"
    {
    echo ''
    echo 'PackagePipeline(new RepoPackage(this))'
    echo ''
    } >> "$jenkins"

    git add "$jenkins"
}

write_agentyaml(){
    local pkg="$1"
    local agent="$pkg"/.artixlinux/agent.yaml label='master'
    [[ -d $pkg/.artixlinux ]] || mkdir "$pkg"/.artixlinux

    echo '%YAML 1.2' > "$agent"
    {
    echo '---'
    echo ''
    echo "label: $label"
    echo ''
    } >> "$agent"

    git add "$agent"
}

commit_jenkins_files(){
    local pkg="$1"

    write_jenkinsfile "$pkg"
    write_agentyaml "$pkg"

    git commit -m "initial commit"
}

#}}}
