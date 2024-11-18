#!/bin/bash

export LC_ALL=C.UTF-8
#shopt -s dotglob

. cmd.sh

function checkSubRegex() {
    for file in "$1"/* ; do
        if [[ -d "$file" ]] ; then
            checkSubRegex "$file" "$2" $3 $4 $5 $6
            output=$?
            if [[ $output -eq 0 ]] ; then
                #cmd mkdir 
                break
            fi
        else
            if [[ $4 =~ "${file##*/}" ]];then
                cmd mkdir -p "$2" $3 $5 $6
                return 0
            fi
        fi
    done
    return 1
}
