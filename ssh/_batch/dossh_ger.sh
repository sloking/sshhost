#!/bin/bash
#
SSH_WORKDIR="${HOME}/.ssh"

if ! [[ -d ${SSH_WORKDIR}/config/ ]];then
        mkdir ${SSH_WORKDIR}/config/
fi

if ! [[ -d ${SSH_WORKDIR}/_batch/open_conn  ]];then
        mkdir ${SSH_WORKDIR}/_batch/open_conn
fi

cd ${SSH_WORKDIR}/config/

source ../_batch/log4bash.sh
SSH_DATETIME=$(date +%s)
SSH_USERNAME_HOST=${1}
SSH_HOSTN=${1#*@}
SSH_USERNAME=${1%%@*}
SSH_LOGFILE="../log/sshconnect.log"
#SSH_CONNPORTFILE="../_batch/openports"
SSH_CONNECTUSER=$(tail -n 3 /var/log/auth.log | grep 'for user from' | awk '{print $11}')
SSH_CONNECTUSER_UNDERLINE=$(echo ${SSH_CONNECTUSER} | tr '.' '_')
SSH_COMMAND="${2} ${3} ${4} ${5} ${6}"
SSH_BASHPID=${BASHPID}
SHORT_BASHPID=${BASHPID}

#log "$SSH_DATETIME" >> ${SSH_LOGFILE} 2>&1

if [ ${#BASHPID} -eq 3 ];then
	SSH_BASHPID="${BASHPID}   "
elif [ ${#BASHPID} -eq 4 ];then
        SSH_BASHPID="${BASHPID}  "
elif [ ${#BASHPID} -eq 5 ];then
        SSH_BASHPID="${BASHPID} "
elif [ ${#BASHPID} -eq 6 ];then
        SSH_BASHPID="${BASHPID}"
fi


#******************************************************************************************************


check_opencon () {

	old_dir=$(pwd)
	cd ${SSH_WORKDIR}/_batch/open_conn
	FILESTOREMOVE=""
	for openfiles in $(ls)
	do
		cont1_pid=""
		cont2_process=""
		#echo "Filename "${openfiles}

		while IFS= read -r openfilesline
		do
			#echo "   Content"  ${openfilesline}
			if [[ -z $cont1_pid  ]];then
				cont1_pid=${openfilesline}
			else
				cont2_process=${openfilesline}
			fi

		done < ${openfiles}

		#echo "		cont1=" ${cont1_pid}
		#echo "		cont2=" ${cont2_process}

		#Datei ausgelesen, jetzt auswerten

		if [[ -f /proc/${cont1_pid}/cmdline ]];then
			#echo "    --->  ${PID1} ist da  --------------------"
			if [[ -z $(grep ${cont2_process} /proc/${cont1_pid}/cmdline) ]];then
				#echo "    -------->  Prozess existiert  --------------------"
			#else
				echo "    -------->  Prozess existiert NICHT "
				FILESTOREMOVE="${FILESTOREMOVE} ${openfiles}"
			fi
		else
			#echo "    --->  ${PID1} ist NICHT da"
			FILESTOREMOVE="${FILESTOREMOVE} ${openfiles}"

		fi

	done

	#echo $FILESTOREMOVE
	if [[ ! -z $FILESTOREMOVE  ]];then
		rm $FILESTOREMOVE
	fi


	cd ${old_dir}

}



#******************************************************************************************************



program_main () {

log "" "" >> ${SSH_LOGFILE} 2>&1
log "${SSH_BASHPID}" "*****************************************************" >> ${SSH_LOGFILE} 2>&1
log "${SSH_BASHPID}" "Verbindungsanfrage von Rechner ${SSH_CONNECTUSER}, Ziel: ${SSH_HOSTN} als user ${SSH_USERNAME}" >> ${SSH_LOGFILE} 2>&1


if [[ "${SSH_USERNAME_HOST}" == "${SSH_USERNAME}" ]];then
        echo "Falscher oder kein Parameter angegeben, Syntax: sshh user@hostname"
        log_error "${SSH_BASHPID}" "Falscher Parameter" >> ${SSH_LOGFILE} 2>&1
        exit 1
fi

if [ "${SSH_HOSTN}" ];then
	#echo "${SSH_HOSTN}_${SSH_USERNAME}"
	SSH_FNAME="$(ls | grep -i ${SSH_HOSTN}_${SSH_USERNAME} | head -n 1)"
	if [ ! -z "${SSH_FNAME}" ] ;then
		touch "../_batch/open_conn/${SHORT_BASHPID}_${SSH_CONNECTUSER_UNDERLINE}_${SSH_USERNAME}_${SSH_HOSTN}"
		echo "${SHORT_BASHPID}" > "../_batch/open_conn/${SHORT_BASHPID}_${SSH_CONNECTUSER_UNDERLINE}_${SSH_USERNAME}_${SSH_HOSTN}"
		echo "${SSH_USERNAME_HOST}" >> "../_batch/open_conn/${SHORT_BASHPID}_${SSH_CONNECTUSER_UNDERLINE}_${SSH_USERNAME}_${SSH_HOSTN}"
		#echo " ssh -i ~/.ssh/config/${SSH_FNAME%*.} ${SSH_USERNAME_HOST}"
		if [[ "${SSH_COMMAND}" == "    " ]];then
			log_success "${SSH_BASHPID}" "SSL-Key ${SSH_FNAME} ist vorhanden, Verbindung wird hergestellt" >> ${SSH_LOGFILE} 2>&1
			ssh -i ~/.ssh/config/"${SSH_FNAME%*.}" ${SSH_USERNAME_HOST} && $(NOW=$(date +%s); log "${SSH_BASHPID}" "Verbindung beendet - von ${SSH_CONNECTUSER} nach ${SSH_USERNAME}@${SSH_HOSTN} - Dauer: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1) || $(NOW=$(date +%s); log "${SSH_BASHPID}" "Verbindung beendet - von ${SSH_CONNECTUSER} nach ${SSH_USERNAME}@${SSH_HOSTN} - Dauer: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1)
		else
			log_success "${SSH_BASHPID}" "SSL-Key ${SSH_FNAME} ist vorhanden, Verbindung wird hergestellt (mit Parameterübergabe)" >> ${SSH_LOGFILE} 2>&1
			ssh -i ~/.ssh/config/"${SSH_FNAME%*.}" ${SSH_USERNAME_HOST} "${SSH_COMMAND}" && $(NOW=$(date +%s); log "${SSH_BASHPID}" "Verbindung beendet - von ${SSH_CONNECTUSER} nach ${SSH_USERNAME}@${SSH_HOSTN} - Dauer: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1) || $(NOW=$(date +%s); log "${SSH_BASHPID}" "Verbindung beendet - von ${SSH_CONNECTUSER} nach ${SSH_USERNAME}@${SSH_HOSTN} - Dauer: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1)
		fi
		rm "../_batch/open_conn/${SHORT_BASHPID}_${SSH_CONNECTUSER_UNDERLINE}_${SSH_USERNAME}_${SSH_HOSTN}"
	else
		log_warning "${SSH_BASHPID}" "SSH Verbindung noch nicht vorhanden! Nachfrage nach Erstellung" >> ${SSH_LOGFILE} 2>&1
		echo "-----> SSH Verbindung nach Host '${SSH_HOSTN}' als User '${SSH_USERNAME}' noch nicht vorhanden!"
		read -n 1 -p "-----> -----> erstellen? [j/n] " SSH_QUEST
		echo -e "\n"
		if [ ! "${SSH_QUEST}" == "j" ] && [ ! "${SSH_QUEST}" == "n" ];then
			log_error "${SSH_BASHPID}" "Keine gültige Antwort gegeben. Abbruch..." >> ${SSH_LOGFILE} 2>&1
			#echo -e "\n"
			echo "-----> -----> Bitte nur j oder n eingeben ! Abbruch..."
			echo -e "\n"
			exit 1
		else
			if [ "${SSH_QUEST}" == "j" ];then
				log "${SSH_BASHPID}" "Nachfrage zugestimmt, SSL-Keys werden erzeugt und auf Rechner kopiert" >> ${SSH_LOGFILE} 2>&1
				SSH_FNAME="id_rsa_${SSH_HOSTN}_${SSH_USERNAME}"
				echo "-----> Erzeugen der Keys"
				ssh-keygen -t rsa -N "" -f "${SSH_FNAME}"
				echo "-----> Kopieren der Dateien auf den Host ${SSH_HOSTN}"

				if [ "$(ssh-copy-id -i ~/.ssh/config/"${SSH_FNAME}".pub "${SSH_USERNAME_HOST}")" ]; then
					log_success "${SSH_BASHPID}" "SSL-Keys wurden kopiert" >> ${SSH_LOGFILE} 2>&1
					program_main
				else
					echo "-----> Kopieren der Dateien fehlgeschlagen. Abbruch..."
					log_error "${SSH_BASHPID}" "SSL-Keys wurden NICHT kopiert!" >> ${SSH_LOGFILE} 2>&1
					rm ~/.ssh/config/"${SSH_FNAME}".pub
					rm ~/.ssh/config/"${SSH_FNAME}"
					log "${SSH_BASHPID}" "SSL-Keys gelöscht" >> ${SSH_LOGFILE} 2>&1
				fi
			else
				log "${SSH_BASHPID}" "Nachfrage wurde nicht zugestimmt. Abbruch..." >> ${SSH_LOGFILE} 2>&1
				echo "-----> Abgebrochen..."
				exit 1
			fi
		fi
	fi
else
	echo "Falscher oder kein Parameter angegeben, Syntax: sshh user@hostname"
	log_error "${SSH_BASHPID}" "Falscher Parameter" >> ${SSH_LOGFILE} 2>&1
	exit 1
fi
}

sec_to_time() {
    local ONE=$1
    local TWO=$2
    local seconds=$((ONE - TWO))
    local sign=""
    if [[ ${seconds:0:1} == "-" ]]; then
        seconds=${seconds:1}
        sign="-"
    fi
    local hours=$(( seconds / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    seconds=$(( seconds % 60 ))
    if [[ $hours -gt 0 ]];then
	printf "%s%02dh %02dm %02ds" "$sign" $hours $minutes $seconds
    elif [[ $hours -eq 0 ]] && [[ $minutes -gt 0 ]];then
	printf "%s%02dm %02ds" "$sign" $minutes $seconds
    elif [[ $hours -eq 0 ]] && [[ $minutes -eq 0 ]];then
	printf "%s%02ds" "$sign" $seconds
    fi
}


check_opencon
program_main
