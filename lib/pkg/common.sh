#!/hint/bash

#{{{ common functions

get_compliant_name(){
    local gitname="$1"
    case "$gitname" in
        *+) gitname=${gitname//+/plus}
    esac
    echo "$gitname"
}

get_pkg_org(){
    local pkg="$1" org sub
    case ${pkg} in
        ruby-*) org="packagesRuby" ;;
        perl-*) org="packagesPerl" ;;
        python-*|python2-*) org="packagesPython" ;;
        *) sub=${pkg:0:1}; org="packages${sub^^}" ;;
    esac
    echo "$org"
}

#}}}
