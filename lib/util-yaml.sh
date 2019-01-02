#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

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
