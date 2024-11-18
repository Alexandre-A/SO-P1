#!/bin/bash

export LC_ALL=C.UTF-8

function cmd() {
    OIFS=$IFS
    IFS=$'\n'
    case "$1" in
        mkdir)
            if [[ "$2" == "-p" ]] ; then
                bdir="$3"
                firstarg="${@:1:2}"

                fakebdir=$(realpath -s -q --relative-to="$(realpath -q "${@: -2:1}")" "${bdir%/*}")
                fakebdir=$(echo "$fakebdir" | sed 's|^\.\.\/||')
                command="$firstarg $fakebdir/${bdir##*/}"
            else
                bdir="$2"
                firstarg="$1"

                fakebdir=$(realpath -s -q --relative-to="$(realpath -q "${@: -2:1}")" "${bdir%/*}")
                fakebdir=$(echo "$fakebdir" | sed 's|^\.\.\/||')

                command="$firstarg $fakebdir/${bdir##*/}"
            fi

            ;;
        rm)
            dir="$2"
            firstarg="$1"

            fakedir=$(realpath -s -q --relative-to="$(realpath -q "${@: -1}")" "${dir%/*}")
            fakedir=$(echo "$fakebdir" | sed 's|^\.\.\/||')

            command="$firstarg $fakedir/${dir##*/}"
            ;;
        cp)
            wdir="$3"
            bdir="$4"
            firstarg="${@:1:2}"

            fakebdir=$(realpath -s -q --relative-to="$(realpath -q "${@: -2:1}")" "${bdir%/*}")
            fakewdir=$(realpath -s -q --relative-to="$(realpath -q "${@: -1}")" "${wdir%/*}")
            fakebdir=$(echo "$fakebdir" | sed 's|^\.\.\/||')
            fakewdir=$(echo "$fakewdir" | sed 's|^\.\.\/||')
            command="$firstarg $fakewdir/${wdir##*/} $fakebdir/${bdir##*/}"
            ;;
        rmdir)
            bdir="$2"

            fakebdir=$(realpath -s -q --relative-to="$(realpath -q "${@: -1}")" "${bdir%/*}")
            fakebdir=$(echo "$fakebdir" | sed 's|^\.\.\/||')
            command="$firstarg $fakebdir/${bdir##*/}"
            ;;
    esac
    [[ "${@: -3:1}" -eq 0 ]] && echo $command || (echo $command && ${@:1:$#-3})
    out=$?
    IFS=$OIFS
    return $out
}
