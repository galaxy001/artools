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

write_users_conf(){
    local conf="$1/users.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo "---" > "$conf"
    echo "defaultGroups:" >> "$conf"
    local IFS=','
    for g in ${addgroups[@]};do
        echo "    - $g" >> "$conf"
    done
    unset IFS
    echo "autologinGroup:  autologin" >> "$conf"
    echo "doAutologin:     false" >> "$conf"
    echo "sudoersGroup:    wheel" >> "$conf"
    echo "setRootPassword: true" >> "$conf"
    echo "availableShells: /bin/bash, /bin/zsh" >> "$conf" # only used in new 'users' module

#     echo "passwordRequirements:" >> "$conf"
#     echo "    minLength: -1" >> "$conf"
#     echo "    maxLength: -1" >> "$conf"
#     echo "    libpwquality:" >> "$conf"
#     echo "        - minlen=8" >> "$conf"
#     echo "        - minclass=80" >> "$conf"
}

write_servicescfg_conf(){
    local init="$2"
    local conf="$1"/services-"$init".conf
    msg2 "Writing %s ..." "${conf##*/}"
    echo '---' >  "$conf"
    case "$init" in
        'runit')
            echo 'svDir: /etc/runit/sv' >> "$conf"
            echo '' >> "$conf"
            echo 'runsvDir: /etc/runit/runsvdir' >> "$conf"
            echo '' >> "$conf"
            echo 'services:' >> "$conf"
            echo "    enabled:" >> "$conf"
            for svc in ${services[@]};do
                echo "      - name: $svc" >> "$conf"
                echo '        runlevel: default' >> "$conf"
            done
        ;;
        'openrc')
            echo 'initdDir: /etc/init.d' >> "$conf"
            echo '' >> "$conf"
            echo 'runlevelsDir: /etc/runlevels' >> "$conf"
            echo '' >> "$conf"
            echo 'services:' >> "$conf"
            for svc in ${services[@]};do
                echo "      - name: $svc" >> "$conf"
                echo '        runlevel: default' >> "$conf"
            done
        ;;
    esac
}

write_postcfg_conf(){
    local conf="$1/postcfg.conf" init="$2"
    sed -e "s|openrc|$init|" -i "$conf"
}

configure_calamares(){
    local mods="$1/etc/calamares/modules" init="$2"
    if [[ -d "$mods" ]];then
        info "Configuring [Calamares]"
        write_users_conf "$mods"
        write_servicescfg_conf "$mods" "$init"
        write_postcfg_conf "$mods" "$init"
        local name=services-"$init"
        sed -e "s|services-openrc|$name|" -i "$1"/etc/calamares/settings.conf
        info "Done configuring [Calamares]"
    fi
}
