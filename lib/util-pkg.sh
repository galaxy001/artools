#!/hint/bash

#{{{ pkg conf

load_pkg_config(){

    local conf="$1/artools-pkg.conf"

    [[ -f "$conf" ]] || return 1

    # shellcheck disable=1090
    [[ -r "$conf" ]] && . "$conf"

    DOMAIN='artixlinux.org'

    GIT_DOMAIN="gitea.${DOMAIN}"

    GIT_URL="https://${GIT_DOMAIN}"

    GIT_TOKEN=${GIT_TOKEN:-''}

    TREE_DIR_ARTIX=${TREE_DIR_ARTIX:-"${WORKSPACE_DIR}/artixlinux"}

    ARTIX_TREE=(
        packages community
        packages-{gfx,gtk,media,net,qt5,xorg}
    )

    local dev_tree=(packages-{python,perl,java,ruby})

    local init_tree=(packages-{openrc,runit,s6})

    local desktop_tree=(
        packages-{kf5,plasma,kde,qt6}
        packages-{lxqt,gnome,cinnamon,mate,xfce,wm}
    )

    [[ -z ${TREE_NAMES_ARTIX[*]} ]] && \
    TREE_NAMES_ARTIX=(
        packages-kernel
        "${init_tree[@]}"
        "${dev_tree[@]}"
        "${desktop_tree[@]}"
        packages-devel
        packages-lib32
    )

    ARTIX_TREE+=("${TREE_NAMES_ARTIX[@]}")

    HOST_TREE_ARTIX=${HOST_TREE_ARTIX:-"gitea@${GIT_DOMAIN}:artixlinux"}

    TREE_DIR_ARCH=${TREE_DIR_ARCH:-"${WORKSPACE_DIR}/archlinux"}

    ARCH_TREE=(packages community)

    HOST_TREE_ARCH=${HOST_TREE_ARCH:-'git://git.archlinux.org/svntogit'}

    CHROOTS_PKG="${CHROOTS_DIR}/buildpkg"

    REPOS_ROOT=${REPOS_ROOT:-"${WORKSPACE_DIR}/repos"}

    REPOS_MIRROR=${REPOS_MIRROR:-'http://mirror1.artixlinux.org/repos'}

    DBEXT=${DBEXT:-'xz'}

    LINKSDBEXT=${LINKSDBEXT:-"links.tar.${DBEXT}"}

    PKGDBEXT=${PKGDBEXT:-"db.tar.${DBEXT}"}

    return 0
}

#}}}

load_pkg_config "${USER_CONF_DIR}" || load_pkg_config "${SYSCONFDIR}"
