#!/hint/bash

##{{{ repo

shopt -s extglob

set_arch_repos(){
    local _testing="${1:-false}" _staging="${2:-false}" _unstable="${3:-false}"
    # shellcheck disable=1090
    . "${DATADIR}"/valid-names.conf

    ARCH_REPOS=("${stable[@]}")

    $_testing && ARCH_REPOS+=("${gremlins[@]}")
    $_staging && ARCH_REPOS+=("${goblins[@]}")
    $_unstable && ARCH_REPOS+=("${unstable[@]}")
}

find_repo(){
    local pkg="$1" repo pkgarch="${2:-${CARCH}}"
    for r in "${ARCH_REPOS[@]}"; do
        [[ -f $pkg/repos/$r-$pkgarch/PKGBUILD ]] && repo=repos/"$r-$pkgarch"
        [[ -f $pkg/repos/$r-any/PKGBUILD ]] && repo=repos/"$r"-any
        [[ -f $pkg/$pkgarch/$r/PKGBUILD ]] && repo="$pkgarch/$r"
    done
    echo "$repo"
}

find_pkg(){
    local searchdir="$1" pkg="$2" result
    result=$(find "$searchdir" -mindepth 2 -maxdepth 2 -type d -name "$pkg")
    echo "$result"
}

#}}}
