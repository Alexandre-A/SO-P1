#!/bin/bash

export LC_ALL=C

function cmd() {
    OIFS=$IFS
    IFS=$'\n'
    [[ "${@: -1}" -eq 0 ]] && echo "${@:1:$#-1}" || (echo ${@:1:$#-1} && ${@:1:$#-1})
    out=$?
    IFS=$OIFS
    return $out
}
