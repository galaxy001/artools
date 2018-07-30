 #!/bin/bash

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
    curl -X POST "${git_url}/api/v1/org/packages/repos?access_token=${git_token}" -H "accept: application/json" -H "content-type: application/json" -d "{\"name\":\"$gitname\"}"
}

delete_repo(){
    local pkg="$1"
    local gitname=$(get_compliant_name "$pkg")
    curl -X DELETE "${git_url}/api/v1/repos/packages/$gitname?access_token=${git_token}" -H  "accept: application/json"
}

add_repo_to_team(){
    local pkg="$1" repo="$2"
    local id=0
    case $repo in
        core) id=18 ;;
        extra) id=19 ;;
        community) id=20 ;;
        multilib) id=21 ;;
    esac

    curl -X PUT "${git_url}/api/v1/teams/$id/repos/packages/$pkg?access_token=${git_token}" -H  "accept: application/json"
}
