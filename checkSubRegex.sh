#!/bin/bash

export LC_ALL=C.UTF-8
#shopt -s dotglob

. cmd.sh

function checkSubRegex() {
    for file in "$1"/* ; do
        if [[ -d "$file" ]] ; then
            checkSubRegex "$file" "$2" $3 $4
            output=$?
            if [[ $output -eq 0 ]] ; then
                cmd mkdir -p "$2" $3
                break
            fi
        else
            if [[ "${file##*/}" =~ $4 ]];then
                cmd mkdir -p "$2" $3
                return 0
            fi
        fi
    done
    return 1
}
