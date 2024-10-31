#!/bin/bash

function cmd(){
	[[ $2 -eq 0 ]] && echo $1 || (echo $1 && $1)
}

newFolder=1
OPTSTRING=":cb:r:"
opcao=1   
opcao2=1   
while getopts ${OPTSTRING} opt; do
  case ${opt} in
    c)
      opcao=0
      ;;
    b)
      echo "Option -b was triggered, Argument: ${OPTARG}"
      ;;
    r)
      echo "Option -r was triggered, Argument: ${OPTARG}"
      opcao2=0
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
	mkdir "$BACKUPFOLDER"
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
            if [[ $opcao2 -ne 0 || ${file##*/} =~ ^$REGEX$ ]];then
               	if [[ "$file" -nt "${BACKUPFOLDER}/${file##*/}" ]]; then
			cmd "cp -a $file ${BACKUPFOLDER}/${file##*/}" $opcao
		elif [[ "${BACKUPFOLDER}/${file##*/}" -nt "$file" ]]; then
			echo "WARNING: backup entry ${BACKUPFOLDER}/${file##*/} is newer than ${WORKFOLDER}/${file##*/}; Should not happen"
		fi
            fi
        elif [[ -d $file ]]; then
            indexNewDirectory=$(( $# - 1 )) #Devido à ordem de passagem dos argumentos
            #${!indexNewDirectory}="$file" Não dá para atribuir valores com indirect expansion
            # Por isso, uma vez que $@ retorna um array com os argumentos, usamos array slicing + set
            # para modificar os argumentos posicionais
            #
            NEWFOLDERNAME="${BACKUPFOLDER}/${file##*/}"
            set -- "${@:1:((indexNewDirectory - 1))}" "$file" "$NEWFOLDERNAME"
            #echo $@
            
            echo -e "\n" #-e enables interpretation of backslash escapes" 
            if ! [ -d  "$NEWFOLDERNAME" ]; then
                if [ -f "$NEWFOLDERNAME" ]; then
	            echo "Já existe um ficheiro com este nome, impossível criar a diretoria de backup"
	        else
                    	             cmd "mkdir $NEWFOLDERNAME" $opcao
                fi  

            fi

            ./backup.sh "$@"
        fi
done
