#!/bin/bash

export LC_ALL=C.UTF-8

#----------------------Variable initialization--------------------------#
shopt -s dotglob

if [[ $# -ne 2 ]]; then
	echo "Não foram passados 2 argumentos como diretoria"
	exit 1
fi

WORKFOLDER="$1"
BACKUPFOLDER="$2"

if ! [ -d "$WORKFOLDER" ]; then
	echo "Diretoria de trabalho não existe"
	exit 1
fi

if ! [ -d "$BACKUPFOLDER" ]; then
	echo "Diretoria de backup não existe"
	exit 1
fi

if [[ "$WORKFOLDER" == "$BACKUPFOLDER" ]]; then
	echo "As diretorias escolhidas são iguais, escolha diretorias diferentes"
	exit 1
fi

WORKFOLDER=$(realpath "$WORKFOLDER")
BACKUPFOLDER=$(realpath "$BACKUPFOLDER")

for file in "$BACKUPFOLDER"/*; do
	if [[ -f "$file" ]]; then
		#echo "$file"
		if [[ -f "${WORKFOLDER}/${file##*/}" ]]; then
			a=$(md5sum "$file" | awk '{print $1}')
			b=$(md5sum "${WORKFOLDER}/${file##*/}" | awk '{print $1}')
			if ! [[ "$a" == "$b" ]]; then
				echo "${WORKFOLDER}/${file##*/} $file differ."
			fi
		fi
	elif [[ -d "$file" && -d "$WORKFOLDER/${file##*/}" ]]; then
		set -- "$WORKFOLDER/${file##*/}" "$BACKUPFOLDER/${file##*/}"
		./backup_check.sh "$@"
	fi
done
