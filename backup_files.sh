#!/bin/bash

export LC_ALL=C.UTF-8

. cmd.sh

#----------------------Variable initiation--------------------------#
shopt -s dotglob
newFolder=1
OPTSTRING=":c"
optc=1
#-----------------------------------------------------------------------#

while getopts ${OPTSTRING} opt; do
    case ${opt} in
    c)
        #echo "Option -c was triggered, Argument: ${OPTARG}"
        optc=0
        ;;
    ?)
        echo "Invalid option: -${OPTARG}." 1>&2
        exit 1
        ;;
    esac
done

if [[ $(($# - $OPTIND + 1)) -ne 2 ]]; then #+1 porque o getopts indica o index seguinte do ultimo getopts flag
    echo "Não foram passados 2 argumentos como diretoria" 1>&2
    exit 1
fi

# echo ${!OPTIND} #indirect expansion

if ! [ -d "${!OPTIND}" ]; then
    echo "Diretoria de trabalho não existe" 1>&2
    exit 1
fi

WORKFOLDER=${!OPTIND}

SECDIR=$(($OPTIND + 1))
BACKUPFOLDER=${!SECDIR}

if [[ "$WORKFOLDER" == "$BACKUPFOLDER" ]]; then
    echo "As diretorias escolhidas são iguais, escolha diretorias diferentes" 1>&2
    exit 1
fi

comp="$(realpath "BACKUPFOLDER")" # variável de comparação
if [[ "$(dirname "BACKUPFOLDER")" == "." && $optc -eq 0 ]] ; then
    comp="."
fi
if [[ "$(realpath "$comp")" == "$(realpath "$WORKFOLDER")"* ]]; then
    echo "A diretoria escolhida como destino de backup está contida na diretoria de trabalho" 1>&2
    echo "Escolha uma diretoria diferente" 1>&2
    exit 1 
fi


if ! [ -d "$BACKUPFOLDER" ]; then
    if [ -f "$BACKUPFOLDER" ]; then
        echo "Impossível criar a diretoria de backup $BACKUPFOLDER, já existe um ficheiro com o mesmo nome" 1>&2
        exit 1
    else
        cmd mkdir "$BACKUPFOLDER" $optc
        newFolder=0
    fi

fi

for file in "$WORKFOLDER"/*; do
    if [[ -f $file ]]; then
        if [[ -f "${BACKUPFOLDER}/${file##*/}" ]]; then
            mod_time1=$(stat -c %Y "${file}")
            mod_time2=$(stat -c %Y "${BACKUPFOLDER}/${file##*/}")
            #echo $mod_time1
            #echo $mod_time2

            if [[ $mod_time2 -gt $mod_time1 ]]; then
                echo "WARNING: backup entry ${BACKUPFOLDER}/${file##*/} is newer than ${WORKFOLDER}/${file##*/}; Should not happen" 1>&2
                continue
            elif [[ $mod_time1 -eq $mod_time2 ]]; then
                continue
            fi
        fi
        cmd cp -a "$file" "${BACKUPFOLDER}/${file##*/}" $optc
    fi
done

for file in "$BACKUPFOLDER"/*; do
    if [[ -f "$file" ]]; then
        if ! [ -f "${WORKFOLDER}/${file##*/}" ]; then
            cmd rm "$file" $optc
        fi
    fi
done
