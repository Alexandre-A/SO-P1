#!/bin/bash

export LC_ALL=C.UTF-8

function recursiveDeletion(){
    # $1 -> directory; $2 -> optc
    local dir="$1"
    local optc="$2"
    if ! [ -n "$(find "$dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then #Se a diretoria estiver vazia
        cmd rmdir "$1" $optc "$3" "$4"
    else
        for file in "$dir"/*; do
            if [[ -f "$file" ]];then
                cmd rm "$file" $optc "$3" "$4"
            elif [[ -d "$file" ]];then
                recursiveDeletion "$file" $optc "$3" "$4"
            fi
        done
       fi        
    cmd rmdir "$1" $optc "$3" "$4"
}
