export LC_ALL=C
#!/bin/bash

export LC_ALL=C

function cmd() {
    OIFS=$IFS
    IFS=$'
'
    [[ "${@: -1}" -eq 0 ]] && echo "${@:1:$#-1}" || (echo ${@:1:$#-1} && ${@:1:$#-1})
    IFS=$OIFS
}

function checkSubRegex() {
    for file in "$1"/* ; do
        if [[ -d "$file" ]] ; then
            checkSubRegex "$file" "$2" $3
            if [[ $? -eq 0 ]] ; then
                cmd mkdir -p"$2" $3
                break
            fi
        else
            if [[ "${file##*/}" =~ ^$REGEX$ ]];then
                cmd mkdir -p "$2" $3
                return 0
            else
                return 1
            fi
        fi
    done
}

shopt -s dotglob

newFolder=1
OPTSTRING=":cb:r:"
optc=1
optr=1
optb=1
while getopts ${OPTSTRING} opt; do
    case ${opt} in
        c)
            optc=0
            ;;
        b)
            #echo "Option -b was triggered, Argument: ${OPTARG}"
            optb=0
            TFILE=${OPTARG}
            ;;
        r)
            echo "Option -r was triggered, Argument: ${OPTARG}"
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
if [[ $(($# - $OPTIND + 1)) -ne 2 ]]; then
    # $OPTIND +1 porque o getopts indica o index seguinte do ultimo getopts flag
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

if ! [ -d  "$BACKUPFOLDER" ]; then
    if [ -f "$BACKUPFOLDER" ]; then
        echo "Já existe um ficheiro com este nome, impossível criar a diretoria de backup"
        exit 1
    else
        # meter cmd
        #echo "$BACKUPFOLDER"
        #echo $(ls -A "$WORKFOLDER")
        if [[ $optr -eq 0 ]] ; then
            if ! [[ -z $(ls -A "$WORKFOLDER") ]] ; then
                checkSubRegex "$WORKFOLDER" "$BACKUPFOLDER" $optc
            fi
        else
            cmd mkdir "$BACKUPFOLDER" $optc
        fi
        newFolder=0
    fi
fi


WORKFOLDER=$(realpath "$WORKFOLDER")

if ! [[ $newFolder -eq 0 ]] ; then
    BACKUPFOLDER=$(realpath "$BACKUPFOLDER")
fi

if [[ "$BACKUPFOLDER" == "$WORKFOLDER"* ]]; then

    echo "A diretoria escolhida como destino de backup está contida na diretoria de trabalho"
    echo "Escolha uma diretoria diferente"
    exit 1
fi

if [[ $optb -eq 0 ]] ; then
    if ! [[ -f $TFILE ]] ; then
        echo "O ficheiro indicado para a flag -b não é válido"
        echo "Escolha um ficheiro válido"
        exit 1
    fi

    mapfile IGNORE < "$TFILE"
fi

for file in "$WORKFOLDER"/*; do
    ignored=1
    if [[ -f "$file" ]]; then
        if [[ $optb -eq 0 ]] ; then
            for ignfile in "${IGNORE[@]}" ; do
                ignfile=$(echo "${ignfile##*/}" | tr -d '
')
                if [[ "${ignfile##*/}" == "${file##*/}" ]] ; then
                    ignored=0
                    break
                fi
            done
        fi
        if [[ $ignored -eq 1 && ($optr -ne 0 || "${file##*/}" =~ ^$REGEX$) ]];then
            if [[ "$file" -nt "$BACKUPFOLDER/${file##*/}" ]]; then
                #file="$(sed 's/ \+/\'\' /g' <<< $file)"
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
        #echo $@

        #echo -e "
" #-e enables interpretation of backslash escapes" 
        if ! [ -d  "$NEWFOLDERNAME" ]; then
            if [ -f "$NEWFOLDERNAME" ]; then
                echo "Já existe um ficheiro com este nome, impossível criar a diretoria de backup"
            #else
                #newfolder2=0
            fi  

        fi
        ./backup.sh "$@"
        #echo  #-e enables interpretation of backslash escapes" 
    fi
done
