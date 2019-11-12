#!/bin/bash
#
if ! [[ -d ~/.ssh/config/ ]];then
	mkdir ~/.ssh/config/
fi
cd ~/.ssh/config/

source ../_batch/log4bash.sh
SSH_DATETIME=$(date +%s)
SSH_USERNAME_HOST=${1}
SSH_HOSTN=${1#*@}
SSH_USERNAME=${1%%@*}
SSH_LOGFILE="/home/user/.ssh/log/sshconnect.log"
#SSH_CONNPORTFILE="../_batch/openports"
SSH_CONNECTUSER=$(tail -n 10 /var/log/auth.log | grep 'Accepted publickey for user from' | tail -n1 | awk '{print $11}')
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
	if ! [[ -d ~/.ssh/_batch/open_conn  ]];then
		mkdir ~/.ssh/_batch/open_conn
	fi
	cd ~/.ssh/_batch/open_conn
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
				file_user_host=$(echo $cont2_process | tr '@' '_')
				file_ip=$(echo ${openfiles} | sed 's/_'"${file_user_host}"'//g' | sed 's/'"${cont1_pid}"'_//g' | tr '_' '.')
				#echo $file_ip
			fi

		done < ${openfiles}

		#echo "		cont1=" ${cont1_pid}
		#echo "		cont2=" ${cont2_process}

		if [ ${#cont1_pid} -eq 3 ];then
		        cont1_pid_long="${cont1_pid}   "
		elif [ ${#cont1_pid} -eq 4 ];then
		        cont1_pid_long="${cont1_pid}  "
		elif [ ${#cont1_pid} -eq 5 ];then
		        cont1_pid_long="${cont1_pid} "
		elif [ ${#cont1_pid} -eq 6 ];then
		        cont1_pid_long="${cont1_pid}"
		fi

		if [[ -f /proc/${cont1_pid}/cmdline ]];then
			#echo "    --->  ${PID1} is there  --------------------"
			if [[ -z $(grep ${cont2_process} /proc/${cont1_pid}/cmdline) ]];then
				#echo "    -------->  Prozess exist  --------------------"
			#else

				#echo "    -------->  Prozess don't exist"
				log_error "${cont1_pid_long}" "Connection unexpected closed - from host ${file_ip} to ${cont2_process}" >> ${SSH_LOGFILE} 2>&1
				FILESTOREMOVE="${FILESTOREMOVE} ${openfiles}"
			fi
		else
			#echo "    --->  ${PID1} is NOT there"
			log_error "${cont1_pid_long}" "Connection unexpected closed - from host ${file_ip} to ${cont2_process}" >> ${SSH_LOGFILE} 2>&1
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
log "${SSH_BASHPID}" "Connection request from host ${SSH_CONNECTUSER}, target: ${SSH_HOSTN} as user ${SSH_USERNAME}" >> ${SSH_LOGFILE} 2>&1


if [[ "${SSH_USERNAME_HOST}" == "${SSH_USERNAME}" ]];then
        echo "Wrong or no parameter given, sytax: sshh user@hostname"
        log_error "${SSH_BASHPID}" "Wrong parameter" >> ${SSH_LOGFILE} 2>&1
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
			log_success "${SSH_BASHPID}" "ssh key ${SSH_FNAME} exist, connecting..." >> ${SSH_LOGFILE} 2>&1
			ssh -i ~/.ssh/config/"${SSH_FNAME%*.}" ${SSH_USERNAME_HOST} && $(NOW=$(date +%s); log "${SSH_BASHPID}" "Conneection closed - from ${SSH_CONNECTUSER} to ${SSH_USERNAME}@${SSH_HOSTN} - duration: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1) || $(NOW=$(date +%s); log "${SSH_BASHPID}" "Connection closed - from ${SSH_CONNECTUSER} to ${SSH_USERNAME}@${SSH_HOSTN} - duration: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1)
		else
			log_success "${SSH_BASHPID}" "ssh key ${SSH_FNAME} exist, connecting with parameters" >> ${SSH_LOGFILE} 2>&1
			ssh -i ~/.ssh/config/"${SSH_FNAME%*.}" ${SSH_USERNAME_HOST} "${SSH_COMMAND}" && $(NOW=$(date +%s); log "${SSH_BASHPID}" "Connection closed - from ${SSH_CONNECTUSER} to ${SSH_USERNAME}@${SSH_HOSTN} - duration: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1) || $(NOW=$(date +%s); log "${SSH_BASHPID}" "Connection closed - from ${SSH_CONNECTUSER} to ${SSH_USERNAME}@${SSH_HOSTN} - duration: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1)
		fi
		rm "../_batch/open_conn/${SHORT_BASHPID}_${SSH_CONNECTUSER_UNDERLINE}_${SSH_USERNAME}_${SSH_HOSTN}"
	else
		log_warning "${SSH_BASHPID}" "ssh keys not exist! Asking for creation" >> ${SSH_LOGFILE} 2>&1
		echo "-----> ssh keys for host '${SSH_HOSTN}' as user '${SSH_USERNAME}' don't exist!"
		read -n 1 -p "-----> -----> create? [y/n] " SSH_QUEST
		echo -e "\n"
		if [ ! "${SSH_QUEST}" == "y" ] && [ ! "${SSH_QUEST}" == "n" ];then
			log_error "${SSH_BASHPID}" "No correct answer given. Abort..." >> ${SSH_LOGFILE} 2>&1
			#echo -e "\n"
			echo "-----> -----> Please put in only 'y' or 'n' ! Abort..."
			echo -e "\n"
			exit 1
		else
			if [ "${SSH_QUEST}" == "y" ];then
				log "${SSH_BASHPID}" "ssh keys would be created and copied to the host" >> ${SSH_LOGFILE} 2>&1
				SSH_FNAME="id_rsa_${SSH_HOSTN}_${SSH_USERNAME}"
				echo "-----> key creation"
				ssh-keygen -t rsa -N "" -f "${SSH_FNAME}"
				echo "-----> copy files to host ${SSH_HOSTN}"

				if [ "$(ssh-copy-id -i ~/.ssh/config/"${SSH_FNAME}".pub "${SSH_USERNAME_HOST}")" ]; then
					log_success "${SSH_BASHPID}" "ssh keys copied" >> ${SSH_LOGFILE} 2>&1
					program_main
				else
					echo "-----> copy not succesful. Abort..."
					log_error "${SSH_BASHPID}" "ssh keys NOT copied!" >> ${SSH_LOGFILE} 2>&1
					rm ~/.ssh/config/"${SSH_FNAME}".pub
					rm ~/.ssh/config/"${SSH_FNAME}"
					log "${SSH_BASHPID}" "ssh keys removed" >> ${SSH_LOGFILE} 2>&1
				fi
			else
				log "${SSH_BASHPID}" "Question was not approved. Abort..." >> ${SSH_LOGFILE} 2>&1
				echo "-----> Aborted..."
				exit 1
			fi
		fi
	fi
else
	echo "Wrong or no parameter given, sytax: sshh user@hostname"
	log_error "${SSH_BASHPID}" "Wrong parameter" >> ${SSH_LOGFILE} 2>&1
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
