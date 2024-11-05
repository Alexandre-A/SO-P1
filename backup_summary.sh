#!/bin/bash

function cmd() {
    OIFS=$IFS
    IFS=$'\n'
   [[ "${@: -1}" -eq 0 ]] && echo "${@:1:$#-1}" || (echo ${@:1:$#-1} && ${@:1:$#-1})    
    a=$?
    IFS=$OIFS
    return $a
}

function checkSubRegex() { #VER SE AQUI TMB METO A CONTAGEM DOS ERROS!
    for file in "$1"/* ; do
        if [[ -d "$file" ]] ; then
            checkSubRegex "$file" "$2" $3
            if [[ $? -eq 0 ]] ; then
                cmd mkdir -p "$2" $3
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

function recursiveDeletion(){
    # $1 -> directory; $2 -> optc; $3 -> número de erros
    local dir="$1"
    local optc="$2"
    local erros="$3"   
    if ! [ -n "$(find "$dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then #Se a diretoria estiver vazia
        cmd rmdir "$1" $optc
        if ! [[ $? -eq 0 ]];then #Se houve erro a copiar
            erros=$((erros+1))
        fi
        return $erros
    else
        for file in "$dir"/*; do
            if [[ -f "$file" ]];then
                cmd rm "$file" $optc
            if ! [[ $? -eq 0 ]];then #Se houve erro a copiar
                erros=$((erros+1))
            fi
            elif [[ -d "$file" ]];then
                recursiveDeletion "$file" $optc $erros
                erros=$?
            fi
        done
       fi        
    cmd rmdir "$1" $optc 
    if ! [[ $? -eq 0 ]];then #Se houve erro a copiar
            erros=$((erros+1))
    fi
    return $erros

}
#----------------------Variable initiation--------------------------#
shopt -s dotglob
optc=1
optr=1 
optb=1
newFolder=1
declare -a summaryArray=(0 0 0 0 0 0 0)
OPTSTRING=":cb:r:"
showsummary=1

#-----------------------------------------------------------------------#
while getopts ${OPTSTRING} opt; do
  case ${opt} in
    c)
      optc=0
      ;;
    b)
      optb=0
      echo "Option -b was triggered, Argument: ${OPTARG}"
      ;;
    r)
      #echo "Option -r was triggered, Argument: ${OPTARG}"
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

if ! [ -d  "$BACKUPFOLDER" ]; then
if [ -f "$BACKUPFOLDER" ]; then
    echo "» Impossível criar a diretoria de backup $BACKUPFOLDER, já existe um ficheiro com o mesmo nome «"
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
            if ! [[ $? -eq 0 ]];then #Se houve erro a copiar
                 summaryArray[0]=$((summaryArray[0]+1))
            fi

        fi
        newFolder=0
    fi

fi

WORKFOLDER=$(realpath "$WORKFOLDER")
if ! [[ $newFolder -eq 0 ]] ; then
    BACKUPFOLDER=$(realpath "$BACKUPFOLDER")
fi
#echo "$BACKUPFOLDER"

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
    iscopia=1
	if [[ -f "$file" ]]; then
        if [[ $optb -eq 0 ]] ; then
            for ignfile in "${IGNORE[@]}" ; do
                ignfile=$(echo ${ignfile##*/} | tr -d '\n')
                if [[ "${ignfile##*/}" == "${file##*/}" ]] ; then
                    ignored=0
                    break
                fi
            done
        fi
        if [[ $ignored -eq 1 && ($optr -ne 0 || "${file##*/}" =~ ^$REGEX$) ]];then
            showsummary=0
            if [[ "$file" -nt "${BACKUPFOLDER}/${file##*/}" ]]; then
                cmd cp -a "$file" "${BACKUPFOLDER}/${file##*/}" $optc
                if [[ $? -eq 0 ]];then #Se não houve erro a copiar
                    if [[  $optc -ne 0 ]];then #Se não foi ativada a flag -c
                        if ! [[ -f "${BACKUPFOLDER}/${file##*/}" ]]; then #Para ver se o file foi updated ou copied
                            tamanho=$(ls -l "$file" | awk '{print $5}')
                            summaryArray[4]=$(( summaryArray[4]+ tamanho))
                            iscopia=0
                            #echo $tamanho 
                        fi
                        if [[ $iscopia -eq 0 ]];then #Se foi agora copiado (new file)
                            summaryArray[3]=$((summaryArray[3]+1))
                        else
                            summaryArray[2]=$((summaryArray[2]+1))
                        fi
                    fi
                else
                     summaryArray[0]=$((summaryArray[0]+1))
                fi
		elif [[ "${BACKUPFOLDER}/${file##*/}" -nt "$file" ]]; then
			echo "WARNING: backup entry ${BACKUPFOLDER}/${file##*/} is newer than ${WORKFOLDER}/${file##*/}; Should not happen"
                        summaryArray[1]=$((summaryArray[1]+1))
		fi
        fi
    elif [[ -d $file ]]; then
        indexNewDirectory=$(( $# - 2 )) #Devido à ordem de passagem dos argumentos
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
    if [[ -f "$file" ]];then
    #echo "$file"
   	if  ! [[ -f "${WORKFOLDER}/${file##*/}" ]]; then    
            if [[  $optc -ne 0 ]];then
                tamanho=$(ls -l "$file" | awk '{print $5}')
                summaryArray[6]=$(( summaryArray[6]+ tamanho))
                summaryArray[5]=$((summaryArray[5]+1))
            fi    
            cmd rm "$file" $optc
            if ! [[ $? -eq 0 ]];then #Se não houve erro a copiar
                 summaryArray[0]=$((summaryArray[0]+1))
            fi
        fi
    
    elif [[ -d "$file" ]]; then
        if  ! [[ -d "${WORKFOLDER}/${file##*/}" ]]; then
            recursiveDeletion "$file" $optc ${summaryArray[0]}
            errosDeletion=$?
            summaryArray[0]=$((summaryArray[0]+errosDeletion))
        fi
    fi
done

# if backupfolder is empty, rmdir essa directory

if [[ $showsummary -eq 0 ]]; then # apenas dá display se cumprir o regex, no caso do -r estar ativo, ou não usar o -r
    echo "While backuping $WORKFOLDER : ${summaryArray[0]} Errors; ${summaryArray[1]} Warnings; ${summaryArray[2]} Updated; ${summaryArray[3]} Copied (${summaryArray[4]} B); ${summaryArray[5]}  deleted (${summaryArray[6]} B)" 
    echo
fi
