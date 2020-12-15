#!/hint/bash

#{{{ deploy

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
