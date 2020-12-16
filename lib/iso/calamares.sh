#!/hint/bash

#{{{ calamares

write_users_conf(){
    local yaml
    yaml=$(write_yaml_header)
    yaml+=$(write_yaml_map 0 'defaultGroups')
    local IFS=','
    for g in "${ADDGROUPS[@]}"; do
        yaml+=$(write_yaml_seq 2 "$g")
    done
    unset IFS
    yaml+=$(write_yaml_map 0 'autologinGroup' 'autologin')
    yaml+=$(write_yaml_map 0 'doAutologin' 'false')
    yaml+=$(write_yaml_map 0 'sudoersGroup' 'wheel')
    yaml+=$(write_yaml_map 0 'setRootPassword' 'true')
    yaml+=$(write_yaml_map 0 'availableShells' '/bin/bash, /bin/zsh')
#     yaml+=$(write_yaml_map 0 'passwordRequirements')
#     yaml+=$(write_yaml_map 2 'minLength' '-1')
#     yaml+=$(write_yaml_map 2 'maxLength' '-1')
#     yaml+=$(write_yaml_map 2 'libpwquality')
#     yaml+=$(write_yaml_seq 4 "minlen=8")
#     yaml+=$(write_yaml_seq 4 "minclass=80")
    yaml+=$(write_empty_line)
    printf '%s' "${yaml}"
}

write_services_conf(){
    local key1="$1" val1="$2" key2="$3" val2="$4"
    local yaml
    yaml=$(write_yaml_header)
    yaml+=$(write_yaml_map 0 "$key1" "$val1")
    yaml+=$(write_yaml_map 0 "$key2" "$val2")
    yaml+=$(write_yaml_map 0 'services')
    for svc in "${SERVICES[@]}"; do
        yaml+=$(write_yaml_seq 2 "$svc")
    done
    yaml+=$(write_empty_line)
    printf '%s' "${yaml}"
}

write_services_openrc_conf(){
    local conf="$1"/services-openrc.conf
    write_services_conf 'initdDir' '/etc/init.d' 'runlevelsDir' '/etc/runlevels' > "$conf"
}

write_services_runit_conf(){
    local conf="$1"/services-runit.conf
    write_services_conf 'svDir' '/etc/runit/sv' 'runsvDir' '/etc/runit/runsvdir' > "$conf"
}

write_services_s6_conf(){
    local conf="$1"/services-s6.conf
    write_services_conf 'svDir' '/etc/s6/sv' 'dbDir' '/etc/s6/rc/compiled' > "$conf"
}

write_postcfg(){
    local yaml
    yaml=$(write_yaml_header)
    yaml+=$(write_yaml_map 0 'keyrings')
    for k in archlinux artix;do
        yaml+=$(write_yaml_seq 2 "$k")
    done
    yaml+=$(write_empty_line)
    printf '%s' "${yaml}"
}

write_unpackfs() {
    local yaml
    yaml=$(write_yaml_header)
    yaml+=$(write_yaml_map 0 'unpack')
#     if ${persist}; then
#         yaml+=$(write_yaml_seq_map 2 'source' '"/run/artix/bootmnt/LiveOS/rootfs.img"')
#         yaml+=$(write_yaml_map 4 'sourcefs' '"ext4"')
#     else
    yaml+=$(write_yaml_seq_map 2 'source' '"/run/artix/bootmnt/LiveOS/rootfs.img"')
    yaml+=$(write_yaml_map 4 'sourcefs' '"squashfs"')
#     fi
    yaml+=$(write_yaml_map 4 'destination' '""')
    yaml+=$(write_empty_line)
    printf '%s' "${yaml}"
}

configure_calamares(){
    local mods="$1/etc/calamares/modules"
    if [[ -d "$mods" ]];then
        msg2 "Configuring Calamares"
        write_users_conf > "$mods"/users.conf
        write_services_"${INITSYS}"_conf "$mods"
        write_postcfg > "$mods"/postcfg.conf
        write_unpackfs > "$mods"/unpackfs.conf
        sed -e "s|services-openrc|services-${INITSYS}|" \
            -i "$1"/etc/calamares/settings.conf
    fi
}

#}}}