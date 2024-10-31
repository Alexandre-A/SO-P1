#!/bin/bash
#----------------------Variable initialization--------------------------#
shopt -s dotglob
optc=1
optr=1  
newFolder=1
declare -a summaryArray=(0 0 0 0 0 0 0)
OPTSTRING=":cb:r:"
showsummary=1
while getopts ${OPTSTRING} opt; do
  case ${opt} in
    c)
      optc=0
      ;;
    b)
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

for file in "$BACKUPFOLDER"/*; do
    if [[ -f "$file" ]];then
    #echo "$file"
        if [[ -f "${WORKFOLDER}/${file##*/}" ]]; then    
                a=$(md5sum "$file" | awk '{print $1}')
                b=$(md5sum "${WORKFOLDER}/${file##*/}" | awk '{print $1}')
                if ! [[ "$a" == "$b" ]]; then
                    echo "${WORKFOLDER}/${file##*/} $file differ."
                fi
        fi
    
    #elif [[ -d "$file" ]]; then
        # Voltar a chamar o ficheiro, usando o gaslight dos anteriores
        #fi
    elif [[ -d "$file" ]] ; then
        set -- "$WORKFOLDER/${file##*/}" "$BACKUPFOLDER/${file##*/}"
        ./backup_check.sh "$@"
    fi
done



