#!/hint/bash

#{{{ functions

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

get_pkgbasename() {
    local name="$1"
    local rm_pkg=${name%.pkg.tar*}
    rm_pkg=${rm_pkg%-*}
    rm_pkg=${rm_pkg%-*}
    rm_pkg=${rm_pkg%-*}
    echo "$rm_pkg"
}

#}}}
