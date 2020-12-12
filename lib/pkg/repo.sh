#!/hint/bash

##{{{ repo

shopt -s extglob

set_arch_repos(){
    local x="$1" y="$2" z="$3"
    # shellcheck disable=1090
    . "${DATADIR}"/valid-names.conf

    ARCH_REPOS=("${stable[@]}")

    $x && ARCH_REPOS+=("${gremlins[@]}")
    $y && ARCH_REPOS+=("${goblins[@]}")
    $z && ARCH_REPOS+=("${unstable[@]}")
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
    local searchdir="$1" pkg="$2"
    local result
    result=$(find "$searchdir" -mindepth 2 -maxdepth 2 -type d -name "$pkg")
    echo "$result"
}

find_cached_pkgfile() {
    local searchdirs=("$PKGDEST" "$PWD") results=()
    local pkg="$1"
    for dir in "${searchdirs[@]}"; do
        [[ -d "$dir" ]] || continue
        [[ -e "$dir/$pkg" ]] && results+=("$dir/$pkg")
    done
    case ${#results[*]} in
        0)
            return 1
        ;;
        1)
            printf '%s\n' "${results[0]}"
            return 0
        ;;
        *)
            error 'Multiple packages found:'
            printf '\t%s\n' "${results[@]}" >&2
            return 1
        ;;
    esac
}

#}}}
