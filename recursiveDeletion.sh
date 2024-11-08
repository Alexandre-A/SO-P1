#!/bin/bash

export LC_ALL=C

function recursiveDeletion(){
    # $1 -> directory; $2 -> optc
    local dir="$1"
    local optc="$2"
    if ! [ -n "$(find "$dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then #Se a diretoria estiver vazia
        cmd rmdir "$1" $optc 
    else
        for file in "$dir"/*; do
            if [[ -f "$file" ]];then
                cmd rm "$file" $optc
            elif [[ -d "$file" ]];then
                recursiveDeletion "$file" $optc
            fi
        done
       fi        
    cmd rmdir "$1" $optc  
}
