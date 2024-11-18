#!/bin/bash

export LC_ALL=C.UTF-8

. cmd.sh
. checkSubRegex.sh
. probeArgs.sh

shopt -s dotglob




function abandon() {
    rm /tmp/tmp.BACKUPFOLDER.* 2> /dev/null
    rm /tmp/tmp.WORKFOLDER.* 2> /dev/null
    rm /tmp/tmp.BKPFINE.* 2> /dev/null
    exit $1
}

# We MUST avoid the temporary files remaining in the directory!
trap abandon INT

function recursiveDeletion() {
    # $1 -> directory; $2 -> optc; $3 -> número de erros
    local dir="$1"
    local optc="$2"
    local erros="$3"
    local wasEmpty=1
    echo
    if ! [ -n "$(find "$dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then #Se a diretoria estiver vazia
        wasEmpty=0
        cmd rmdir "$1" $optc "$workCache" "$bkpCache"
        if ! [[ $? -eq 0 ]]; then #Se houve erro a copiar
            erros=$((erros + 1))
        fi 
    else
        for file in "$dir"/*; do
            if [[ -f "$file" ]]; then
                cmd rm "$file" $optc "$4" "$5"
                if ! [[ $? -eq 0 ]]; then #Se houve erro a copiar
                    erros=$((erros + 1))
                fi
            elif [[ -d "$file" ]]; then
                recursiveDeletion "$file" $optc $erros "$4" "$5"
                erros=$?
            fi
        done
    fi
    if [[ $wasEmpty -eq 1 ]]; then
        cmd rmdir "$1" $optc "$4" "$5"
        if ! [[ $? -eq 0 ]]; then #Se houve erro a copiar
            erros=$((erros + 1))
        fi
    fi
    return $erros

}
#----------------------Variable initiation--------------------------#
optc=1
optr=1
optb=1
newFolder=1
declare -a summaryArray=(0 0 0 0 0 0 0)
OPTSTRING=":cb:r:"
showsummary=1

workCache=$(cat /tmp/tmp.WORKFOLDER.* 2> /dev/null)
bkpCache=$(cat /tmp/tmp.BACKUPFOLDER.* 2> /dev/null)

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
        echo "Option -${OPTARG} requires an argument." 1>&2
        abandon 1
        ;;
    ?)
        echo "Invalid option: -${OPTARG}." 1>&2
        abandon 1
        ;;
    esac
done

if [[ $(($# - $OPTIND + 1)) -ne 2 ]]; then #+1 porque o getopts indica o index seguinte do ultimo getopts flag
    echo "Não foram passados 2 argumentos como diretoria" 1>&2
    abandon 1
fi

# echo ${!OPTIND} #indirect expansion

if ! [ -d "${!OPTIND}" ]; then
    echo "Diretoria de trabalho não existe" 1>&2
    abandon 1
fi

WORKFOLDER="${!OPTIND}"

SECDIR=$(($OPTIND + 1))
BACKUPFOLDER="${!SECDIR}"

if [[ "$WORKFOLDER" == "$BACKUPFOLDER" ]]; then
    echo "As diretorias escolhidas são iguais, escolha diretorias diferentes" 1>&2
    abandon 1
fi

probeArgs "$WORKFOLDER" "$BACKUPFOLDER" $optr $optc $optb "$TFILE" "$REGEX"
output=$?
if [[ $output -eq 2 ]]; then
    abandon 1
fi

if [[ -z $(ls /tmp/tmp.BKPFINE.* 2> /dev/null) ]] ; then
    comp="$(realpath "$BACKUPFOLDER")" # variável de comparação
    if [[ "$(dirname "$BACKUPFOLDER")" == "." && $optc -eq 0 ]] ; then
        comp="."
    fi
    if [[ "$(realpath "$comp")" == "$(realpath "$WORKFOLDER")"* ]]; then
        echo "A diretoria escolhida como destino de backup está contida na diretoria de trabalho" 1>&2
        echo "Escolha uma diretoria diferente" 1>&2
        abandon 1
    elif [[ -z $(ls /tmp/tmp.BACKUPFOLDER.* 2> /dev/null) ]] ; then
        mktemp -q -t tmp.BKPFINE.XXXXXXXXXX > /dev/null
    fi
fi

if [[ "$workCache" == "" || "$bkpCache" == "" ]] ; then
    workCache="$WORKFOLDER"
    bkpCache="$BACKUPFOLDER"
fi

if ! [ -d "$BACKUPFOLDER" ]; then
    if [ -f "$BACKUPFOLDER" ]; then
        echo "Impossível criar a diretoria de backup $BACKUPFOLDER, já existe um ficheiro com o mesmo nome" 1>&2
        abandon 1
    else
        if [[ $optr -eq 0 ]]; then
            if ! [[ -z $(ls -A "$WORKFOLDER") ]]; then
                checkSubRegex "$WORKFOLDER" "$BACKUPFOLDER" $optc "$REGEX" "$workCache" "$bkpCache"
            fi
        else
            cmd mkdir "$BACKUPFOLDER" $optc "$workCache" "$bkpCache"
            if ! [[ $? -eq 0 ]]; then #Se houve erro a copiar
                summaryArray[0]=$((summaryArray[0] + 1))
            fi

        fi
        newFolder=0
    fi

fi

WORKFOLDER=$(realpath "$WORKFOLDER")
if [[ $? -ne 0 ]]; then
    abandon 1
fi
if [[ $optr -eq 0 ]]; then
    if ! [[ $newFolder -eq 0 ]]; then
        BACKUPFOLDER=$(realpath "$BACKUPFOLDER")
        if [[ $? -ne 0 ]]; then
            abandon 1
        fi
    fi
elif [[ $optc -ne 0 ]]; then
    BACKUPFOLDER=$(realpath "$BACKUPFOLDER")
    if [[ $? -ne 0 ]]; then
        abandon 1
    fi
fi

if [[ -z $(ls /tmp/tmp.BACKUPFOLDER.* 2> /dev/null) && -z $(ls /tmp/tmp.WORKFOLDER.* 2> /dev/null) ]] ; then
    firstRun=0
    mktemp -q -t tmp.WORKFOLDER.XXXXXXXXXX > /dev/null

    if [[ $? -eq 0 ]] ; then
        mktemp -q -t tmp.BACKUPFOLDER.XXXXXXXXXX > /dev/null
        #echo made temps

        if [[ $? -eq 0 ]] ; then
            workCache="$WORKFOLDER"
            bkpCache="$BACKUPFOLDER"
            echo "$workCache" > /tmp/tmp.WORKFOLDER.*
            echo "$bkpCache" > /tmp/tmp.BACKUPFOLDER.*
        fi
    fi
fi


if [[ $optb -eq 0 ]]; then
    mapfile IGNORE <"$TFILE"
fi

for file in "$WORKFOLDER"/*; do
    ignored=1
    iscopia=1
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
            showsummary=0
            if [[ -f "${BACKUPFOLDER}/${file##*/}" ]]; then
                mod_time1=$(stat -c %Y "${file}")
                mod_time2=$(stat -c %Y "${BACKUPFOLDER}/${file##*/}")

                if [[ $mod_time2 -gt $mod_time1 ]]; then
                    echo "WARNING: backup entry ${BACKUPFOLDER}/${file##*/} is newer than ${WORKFOLDER}/${file##*/}; Should not happen" 1>&2
                    summaryArray[1]=$((summaryArray[1] + 1))
                    continue
                elif [[ $mod_time1 -eq $mod_time2 ]]; then
                    continue
                fi
            else
                iscopia=0
            fi

            cmd cp -a "$file" "${BACKUPFOLDER}/${file##*/}" $optc "$workCache" "$bkpCache"
            if [[ $? -eq 0 ]]; then               #Se não houve erro a copiar
                    if [[ $iscopia -eq 0 ]]; then #Se foi agora copiado (new file)
                        summaryArray[3]=$((summaryArray[3] + 1))
                        tamanho=$(ls -l "$file" | awk '{print $5}')
                        summaryArray[4]=$((summaryArray[4] + tamanho))

                    else
                        summaryArray[2]=$((summaryArray[2] + 1))
                    fi
            else
                summaryArray[0]=$((summaryArray[0] + 1))
            fi
        fi
    elif [[ -d $file ]]; then
        if [[ $ignored -eq 0 ]]; then
            continue
        fi
        indexNewDirectory=$(($# - 2)) #Devido à ordem de passagem dos argumentos
        #${!indexNewDirectory}="$file" Não dá para atribuir valores com indirect expansion
        # Por isso, uma vez que $@ retorna um array com os argumentos, usamos array slicing + set
        # para modificar os argumentos posicionais
        #
        NEWFOLDERNAME="${BACKUPFOLDER}/${file##*/}"
        set -- "${@:1:((indexNewDirectory))}" "$file" "$NEWFOLDERNAME"
        #echo $@

        ./backup_summary.sh "$@"
    fi
done

#diff -q "$WORKFOLDER" "$BACKUPFOLDER" | grep "Only"
for file in "$BACKUPFOLDER"/*; do
    if [[ -f "$file" ]]; then
        if ! [ -f "${WORKFOLDER}/${file##*/}" ]; then
            tamanho=$(ls -l "$file" | awk '{print $5}')
            summaryArray[6]=$((summaryArray[6] + tamanho))
            summaryArray[5]=$((summaryArray[5] + 1))
            cmd rm "$file" $optc "$workCache" "$bkpCache"
            if ! [[ $? -eq 0 ]]; then #Se não houve erro a copiar
                summaryArray[0]=$((summaryArray[0] + 1))
            fi
        fi

    elif [[ -d "$file" ]]; then
        if ! [[ -d "${WORKFOLDER}/${file##*/}" ]]; then
            recursiveDeletion "$file" $optc ${summaryArray[0]}
            errosDeletion=$?
            summaryArray[0]=$((summaryArray[0] + errosDeletion))
        fi
    fi
done

# if backupfolder is empty, rmdir the directory
if [[ $showsummary -eq 0 ]]; then # apenas dá display se cumprir o regex, no caso do -r estar ativo, ou não usar o -r
    echo "While backuping $BACKUPFOLDER: ${summaryArray[0]} Errors; ${summaryArray[1]} Warnings; ${summaryArray[2]} Updated; ${summaryArray[3]} Copied (${summaryArray[4]}B); ${summaryArray[5]} Deleted (${summaryArray[6]}B)"
    echo
fi
