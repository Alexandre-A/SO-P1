#!/bin/bash

export LC_ALL=C
#shopt -s dotglob - need to check if this is required here due to the nature of functions in bash

. cmd.sh
. checkSubRegex.sh

function probeArgs() {
    # WORKFOLDER        - 1
    # BACKUPFOLDER      - 2
    # optr              - 3
    # optc              - 4
    # optb              - 5
    # TFILE             - 6
    # REGEX             - 7
    #   return values:
    #       0 - newFolder = 0
    #       1 - standard flow (nothing prone to change)
    #       2 - error

    if [[ -z "$2" ]] ; then
        echo "UNEXPECTED ERROR OCCURRED AT BACKUPFOLDER=$2"
        exit 1
    fi

    if [[ -z "$1" ]] ; then
        echo "UNEXPECTED ERROR OCCURRED AT WORKFOLDER=$1"
        exit 1
    fi

    if [[ $5 -eq 0 ]] ; then
        if ! [[ -f "$6" ]] ; then
            echo "O ficheiro indicado para a flag -b não é válido"
            echo "Escolha um ficheiro válido"
            #exit 1
            return 2
        fi
    #mapfile IGNORE < "$TFILE"
    fi

    if [[ "$2" == "$1"* ]]; then
        echo "A diretoria escolhida como destino de backup está contida na diretoria de trabalho"
        echo "Escolha uma diretoria diferente"
        #exit 1
        return 2
    fi

    if ! [ -d  "$2" ]; then
        if [ -f "$2" ]; then
            echo "» Impossível criar a diretoria de backup $2, já existe um ficheiro com o mesmo nome «"
            #exit 1
            return 2
        else
            # meter cmd
            #echo "$BACKUPFOLDER"
            #echo $(ls -A "$WORKFOLDER")
            if [[ $3 -eq 0 ]] ; then
                if ! [[ -z $(ls -A "$1") ]] ; then
                    checkSubRegex "$1" "$2" $4 $7
                fi
            else
                cmd mkdir "$2" $4
            fi
            #newFolder=0
            return 0
        fi
    fi
}
