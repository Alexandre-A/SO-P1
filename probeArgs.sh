#!/bin/bash

export LC_ALL=C.UTF-8
#shopt -s dotglob - need to check if this is required here due to the nature of functions in bash

. cmd.sh
. checkSubRegex.sh

function probeArgs() {
	# WORKFOLDER        - 1
	# BACKUPFOLDER      - 2
	# optr              - 3
	# optc              - 4
	# optb              - 5
	# TFILE             - 6
	# REGEX             - 7
	#   return values:
	#       0 - newFolder = 0
	#       1 - standard flow (nothing prone to change)
	#       2 - error

	if [[ -z "$2" ]]; then
		echo "UNEXPECTED ERROR OCCURRED AT BACKUPFOLDER=$2" 1>&2
		exit 1
	fi

	if [[ -z "$1" ]]; then
		echo "UNEXPECTED ERROR OCCURRED AT WORKFOLDER=$1" 1>&2
		exit 1
	fi

	if [[ $5 -eq 0 ]]; then
		if ! [[ -f "$6" ]]; then
			echo "O ficheiro indicado para a flag -b não é válido" 1>&2
			echo "Escolha um ficheiro válido" 1>&2
			return 2
		fi
	#mapfile IGNORE < "$TFILE"
	fi


}
