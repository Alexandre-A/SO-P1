export LC_ALL=C
#!/bin/bash

function cmd(){
	[[ $2 -eq 0 ]] && echo $1 || (echo $1 && $1)
}

newFolder=1
OPTSTRING=":c"
opcao=1;   
while getopts ${OPTSTRING} opt; do
  case ${opt} in
    c)
      #echo "Option -c was triggered, Argument: ${OPTARG}"
      opcao=0
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

if ! [ -d  ${!OPTIND} ]; then
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

if ! [ -d  $BACKUPFOLDER ]; then
    if [ -f $BACKUPFOLDER ]; then
        echo "Já existe um ficheiro com este nome, impossível criar a diretoria de backup"
        exit 1
    else
        cmd "mkdir $BACKUPFOLDER"
        newFolder=0
    fi
fi

WORKFOLDER=$(realpath "$WORKFOLDER")
BACKUPFOLDER=$(realpath "$BACKUPFOLDER")
#echo "$BACKUPFOLDER"

if [[ "$BACKUPFOLDER" == "$WORKFOLDER"* ]]; then

    echo "A diretoria escolhida como destino de backup está contida na diretoria de trabalho"
	echo "Escolha uma diretoria diferente"
	if [[ $newFolder -eq 0 ]]; then
		rmdir "$BACKUPFOLDER"
	fi
	exit 1
fi

for file in "$WORKFOLDER"/*; do
	if [[ -f $file ]]; then
		if [[ "$file" -nt "${BACKUPFOLDER}/${file##*/}" ]]; then
			cmd "cp -a $file ${BACKUPFOLDER}/${file##*/}" $opcao
		elif [[ "${BACKUPFOLDER}/${file##*/}" -nt "$file" ]]; then
			echo "WARNING: backup entry ${BACKUPFOLDER}/${file##*/} is newer than ${WORKFOLDER}/${file##*/}; Should not happen"
		fi
	fi
done
 
