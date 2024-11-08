#!/bin/bash

export LC_ALL=C

. cmd.sh
. checkSubRegex.sh
. recursiveDeletion.sh
. probeArgs.sh

#----------------------Variable initiation--------------------------#
shopt -s dotglob
optc=1
optr=1 
optb=1
newFolder=1
OPTSTRING=":cb:r:"
#-----------------------------------------------------------------------#

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
            echo "Option -${OPTARG} requires an argument."
            exit 1
            ;;
        ?)
            echo "Invalid option: -${OPTARG}."
            exit 1
            ;;
    esac
done 

if [[ $(($# - $OPTIND + 1)) -ne 2 ]]; then #+1 porque o getopts indica o index seguinte do ultimo getopts flag
    echo "Não foram passados 2 argumentos como diretoria";
    exit 1
fi

# echo ${!OPTIND} #indirect expansion

if ! [ -d  "${!OPTIND}" ]; then
    echo "Diretoria de trabalho não existe"
    exit 1;
fi

WORKFOLDER="${!OPTIND}"

SECDIR=$(($OPTIND +1))
BACKUPFOLDER="${!SECDIR}"


if [[ "$WORKFOLDER" == "$BACKUPFOLDER" ]]; then
    echo "As diretorias escolhidas são iguais, escolha diretorias diferentes"
    exit 1
fi


probeArgs "$WORKFOLDER" "$BACKUPFOLDER" $optr $optc $optb "$TFILE" "$REGEX"
output=$?
if [[ $output -eq 0 ]] ; then
    newFolder=0
elif [[ $output -eq 2 ]] ; then
    exit 1
fi

WORKFOLDER=$(realpath "$WORKFOLDER")
if [[ $optr -eq 0 ]] ; then
    if ! [[ $newFolder -eq 0 ]] ; then
        BACKUPFOLDER=$(realpath "$BACKUPFOLDER")
        if [[ $? -ne 0 ]] ; then
            exit 1
        fi
    fi

elif [[ $optc -ne 0 ]] ; then
    BACKUPFOLDER=$(realpath "$BACKUPFOLDER")
    if [[ $? -ne 0 ]] ; then
        exit 1
    fi
fi
#echo "$BACKUPFOLDER"

#echo probe output: $output

if [[ $optb -eq 0 ]] ; then
    mapfile IGNORE < "$TFILE"
fi


for file in "$WORKFOLDER"/*; do
    ignored=1
    if [[ -f "$file" ]]; then
        if [[ $optb -eq 0 ]] ; then
            for ignfile in "${IGNORE[@]}" ; do
                ignfile="$(echo "${ignfile}" | tr -d '\n')" # TESTAR COM PATH ABSOLUTO
                if [[ "$ignfile" == "$file" ]] ; then
                    ignored=0
                    break
                fi
            done
        fi
        if [[ $ignored -eq 1 && ($optr -ne 0 || "${file##*/}" =~ $REGEX) ]];then
            if [[ "$file" -nt "${BACKUPFOLDER}/${file##*/}" ]]; then
                cmd cp -a "$file" "${BACKUPFOLDER}/${file##*/}" $optc
            elif [[ "${BACKUPFOLDER}/${file##*/}" -nt "$file" ]]; then
                echo "WARNING: backup entry ${BACKUPFOLDER}/${file##*/} is newer than ${WORKFOLDER}/${file##*/}; Should not happen"
            fi
        fi
    elif [[ -d $file ]]; then
        indexNewDirectory=$(( $# - 2 )) #Devido à ordem de passagem dos argumentos
        #${!indexNewDirectory}="$file" Não dá para atribuir valores com indirect expansion
        # Por isso, uma vez que $@ retorna um array com os argumentos, usamos array slicing + set
        # para modificar os argumentos posicionais
        NEWFOLDERNAME="${BACKUPFOLDER}/${file##*/}"
        set -- "${@:1:((indexNewDirectory))}" "$file" "$NEWFOLDERNAME"

        ./backup.sh "$@"
    fi
done

for file in "$BACKUPFOLDER"/*; do
    if [[ -f "$file" ]];then
        #echo "$file"
        if  ! [[ -f "${WORKFOLDER}/${file##*/}" ]]; then    
            cmd rm "$file" $optc
        fi

    elif [[ -d "$file" ]]; then
        if  ! [[ -d "${WORKFOLDER}/${file##*/}" ]]; then
            recursiveDeletion "$file" $optc 
        fi
    fi
done

