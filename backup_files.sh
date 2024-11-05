#!/bin/bash


function cmd() {
    OIFS=$IFS
    IFS=$'\n'
   [[ "${@: -1}" -eq 0 ]] && echo "${@:1:$#-1}" || (echo ${@:1:$#-1} && ${@:1:$#-1})    
    IFS=$OIFS
}

#----------------------Variable initiation--------------------------#
shopt -s dotglob
newFolder=1
OPTSTRING=":c"
optc=1;  
#-----------------------------------------------------------------------#

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    c)
      #echo "Option -c was triggered, Argument: ${OPTARG}"
      optc=0
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

WORKFOLDER=${!OPTIND}

SECDIR=$(($OPTIND +1))
BACKUPFOLDER=${!SECDIR}

if [[ "$WORKFOLDER" == "$BACKUPFOLDER" ]]; then
	echo "As diretorias escolhidas são iguais, escolha diretorias diferentes"
	exit 1
fi


if ! [ -d  "$BACKUPFOLDER" ]; then
    if [ -f "$BACKUPFOLDER" ]; then
        echo "» Impossível criar a diretoria de backup $BACKUPFOLDER, já existe um ficheiro com o mesmo nome «"
            exit 1
    else
        cmd mkdir "$BACKUPFOLDER" $optc    
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

for file in "$WORKFOLDER"/*; do
	if [[ -f $file ]]; then
		if [[ "$file" -nt "${BACKUPFOLDER}/${file##*/}" ]]; then
			cmd cp -a "$file" "${BACKUPFOLDER}/${file##*/}" $optc
		elif [[ "${BACKUPFOLDER}/${file##*/}" -nt "$file" ]]; then
			echo "WARNING: backup entry ${BACKUPFOLDER}/${file##*/} is newer than ${WORKFOLDER}/${file##*/}; Should not happen"
		fi
	fi
done

for file in "$BACKUPFOLDER"/*; do
    if [[ -f "$file" ]];then
    #echo "$file"
   	if  ! [[ -f "${WORKFOLDER}/${file##*/}" ]]; then    
            cmd rm "$file" $optc
        fi
    fi
done
