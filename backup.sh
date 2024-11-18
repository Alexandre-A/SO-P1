#!/bin/bash

export LC_ALL=C.UTF-8

. cmd.sh
. checkSubRegex.sh
. probeArgs.sh

#----------------------Variable initiation--------------------------#
shopt -s dotglob
optc=1
optr=1
optb=1
newFolder=1
OPTSTRING=":cb:r:"
#-----------------------------------------------------------------------#

function recursiveDeletion() {
    # $1 -> directory; $2 -> optc
    local dir="$1"
    local optc="$2"
    local wasEmpty=1
    if ! [ -n "$(find "$dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then #Se a diretoria estiver vazia
        wasEmpty=0
        cmd rmdir "$1" $optc
    else
        for file in "$dir"/*; do
            if [[ -f "$file" ]]; then
                cmd rm "$file" $optc
            elif [[ -d "$file" ]]; then
                recursiveDeletion "$file" $optc
            fi
        done
    fi
    if [[ $wasEmpty -eq 1 ]]; then
        cmd rmdir "$1" $optc
    fi
}

while getopts ${OPTSTRING} opt; do
    case ${opt} in
    c)
        optc=0
        ;;
    b)
        optb=0
        TFILE=${OPTARG}
        ;;
    r)
        optr=0
        REGEX=${OPTARG}
        ;;
    :)
        echo "Option -${OPTARG} requires an argument." 1>&2
        exit 1
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

WORKFOLDER="${!OPTIND}"

SECDIR=$(($OPTIND + 1))
BACKUPFOLDER="${!SECDIR}"

if [[ "$WORKFOLDER" == "$BACKUPFOLDER" ]]; then
    echo "As diretorias escolhidas são iguais, escolha diretorias diferentes" 1>&2
    exit 1
fi

probeArgs "$WORKFOLDER" "$BACKUPFOLDER" $optr $optc $optb "$TFILE" "$REGEX"
output=$?
if [[ $output -eq 2 ]]; then
    exit 1
fi


if ! [ -d "$BACKUPFOLDER" ]; then
    if [ -f "$BACKUPFOLDER" ]; then
        echo "Impossível criar a diretoria de backup $BACKUPFOLDER, já existe um ficheiro com o mesmo nome" 1>&2
        exit 1
    else
        if [[ $optr -eq 0 ]]; then
            if ! [[ -z $(ls -A "$WORKFOLDER") ]]; then
                checkSubRegex "$WORKFOLDER" "$BACKUPFOLDER" $optc $REGEX
            fi
        else
            cmd mkdir "$BACKUPFOLDER" $optc
        fi
        newFolder=0
    fi
fi

WORKFOLDER=$(realpath "$WORKFOLDER")
if [[ $? -ne 0 ]]; then
    exit 1
fi
if [[ $optr -eq 0 ]]; then
    if ! [[ $newFolder -eq 0 ]]; then
        BACKUPFOLDER=$(realpath "$BACKUPFOLDER")
        if [[ $? -ne 0 ]]; then
            exit 1
        fi
    fi
elif [[ $optc -ne 0 ]]; then
    BACKUPFOLDER=$(realpath "$BACKUPFOLDER")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
fi

if [[ "$(realpath BACKUPFOLDER)" == "$(realpath "$WORKFOLDER")"* ]]; then
    echo "A diretoria escolhida como destino de backup está contida na diretoria de trabalho" 1>&2
    echo "Escolha uma diretoria diferente" 1>&2
    exit 1
fi


if [[ $optb -eq 0 ]]; then
    mapfile IGNORE <"$TFILE"
fi

for file in "$WORKFOLDER"/*; do
    ignored=1
    if [[ $optb -eq 0 ]]; then
        for ignfile in "${IGNORE[@]}"; do
            ignfile="$(echo ${ignfile} | tr -d '\n')"
            if [[ "${ignfile##*/}" == "${file##*/}" ]]; then
                ignored=0
                break
            fi
        done
    fi
    if [[ -f "$file" ]]; then
        if [[ $ignored -eq 1 && ($optr -ne 0 || "${file##*/}" =~ $REGEX) ]]; then
            if [[ -f "${BACKUPFOLDER}/${file##*/}" ]]; then
                mod_time1=$(stat -c %Y "${file}")
                mod_time2=$(stat -c %Y "${BACKUPFOLDER}/${file##*/}")

                if [[ $mod_time2 -gt $mod_time1 ]]; then
                    echo "WARNING: backup entry ${BACKUPFOLDER}/${file##*/} is newer than ${WORKFOLDER}/${file##*/}; Should not happen" 1>&2
                    continue
                elif [[ $mod_time1 -eq $mod_time2 ]]; then
                    continue
                fi
            fi

            cmd cp -a "$file" "${BACKUPFOLDER}/${file##*/}" $optc
        fi
    elif [[ -d $file ]]; then
        if [[ $ignored -eq 0 ]]; then
            continue
        fi
        indexNewDirectory=$(($# - 2)) #Devido à ordem de passagem dos argumentos
        #${!indexNewDirectory}="$file" Não dá para atribuir valores com indirect expansion
        # Por isso, uma vez que $@ retorna um array com os argumentos, usamos array slicing + set
        # para modificar os argumentos posicionais
        NEWFOLDERNAME="${BACKUPFOLDER}/${file##*/}"
        set -- "${@:1:((indexNewDirectory))}" "$file" "$NEWFOLDERNAME"

        ./backup.sh "$@"
    fi
done

for file in "$BACKUPFOLDER"/*; do
    if [[ -f "$file" ]]; then
        if ! [ -f "${WORKFOLDER}/${file##*/}" ]; then
            cmd rm "$file" $optc
        fi

    elif [[ -d "$file" ]]; then
        if ! [[ -d "${WORKFOLDER}/${file##*/}" ]]; then
            recursiveDeletion "$file" $optc
        fi
    fi
done
