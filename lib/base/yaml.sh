#!/hint/bash

#{{{ yaml

write_yaml_header(){
    printf '%s' '---'
}

write_empty_line(){
    printf '\n%s\n' ' '
}

write_yaml_map(){
    local ident="$1" key="$2" val="$3"
    printf "\n%${ident}s%s: %s\n" '' "$key" "$val"
}

write_yaml_seq(){
    local ident="$1" val="$2"
    printf "\n%${ident}s- %s\n" '' "$val"
}

write_yaml_seq_map(){
    local ident="$1" key="$2" val="$3"
    printf "\n%${ident}s- %s: %s\n" '' "$key" "$val"
}

#}}}
