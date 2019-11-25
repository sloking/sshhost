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


source ${SSH_WORKDIR}/_batch/log4bash.sh
SSH_DATETIME=$(date +%s)
SSH_USERNAME_HOST=${1}
SSH_HOSTN=${1#*@}
SSH_USERNAME=${1%%@*}
SSH_LOGFILE="${SSH_WORKDIR}/log/sshconnect.log"
#SSH_CONNPORTFILE="${SSH_WORKDIR}/_batch/openports"
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

check_opencon()
{

	old_dir=$(pwd)
	if ! [[ -d ${SSH_WORKDIR}/_batch/open_conn  ]];then
		mkdir ${SSH_WORKDIR}/_batch/open_conn
	fi
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

check_params()
{

if [[ "${SSH_USERNAME_HOST}" == "--help" ]];then
	params=1
	print_help

elif [[ "${SSH_USERNAME_HOST}" == "--rmkey" ]];then
	params=1
	KEY_TO_DEL=${SSH_COMMAND}
	#echo ${KEY_TO_DEL}
	if ! [[ $(echo ${KEY_TO_DEL} | grep -E '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Za-z0-9.-]\b') ]];then
		echo "! Wrong parameter given!"
		print_help
	else
		SSH_HOSTN_FILE=${KEY_TO_DEL#*@}
		SSH_HOSTN_FILE=$(echo ${SSH_HOSTN_FILE} | sed 's/ //g')
		#echo "hostname ${SSH_HOSTN_FILE}"
		SSH_USERNAME_FILE=${KEY_TO_DEL%@*}
		#echo "user ${SSH_USERNAME_FILE}"
		FILE_TO_DELETE="id_rsa_${SSH_HOSTN_FILE}_${SSH_USERNAME_FILE}"
		FILE_TO_DELETE2="id_rsa_${SSH_HOSTN_FILE}_${SSH_USERNAME_FILE}.pub"
		#echo -e "Delete ${FILE_TO_DELETE}"

		ALL_KEYS=$(ls)
		FILE_FOUND=0
		for ALL_KEY in ${ALL_KEYS}
		do
			if [[ "${ALL_KEY}" == "${FILE_TO_DELETE}" ]];then
				echo ${ALL_KEY}
				FILE_FOUND=1
			fi
		done

                if [[ ${FILE_FOUND} -eq 0 ]];then
                        echo -e "\nNo ssh-key found for \"${SSH_USERNAME_FILE}@${SSH_HOSTN_FILE}\" - file \"${FILE_TO_DELETE}\" not found! Abort...\n"
                        log_error "${SSH_BASHPID}" "Try to delete Keys in the config folder: \"${FILE_TO_DELETE}\" - file NOT found - request from ${SSH_CONNECTUSER}" >> ${SSH_LOGFILE} 2>&1
                else
                        echo -e "\nDelete \"${FILE_TO_DELETE}\" and \"${FILE_TO_DELETE2}\""
                        log_warning "${SSH_BASHPID}" "Delete Keys in the config folder: \"${FILE_TO_DELETE}\" - request from ${SSH_CONNECTUSER}" >> ${SSH_LOGFILE} 2>&1
                        rm -v ${FILE_TO_DELETE}
                        rm -v ${FILE_TO_DELETE2}
                fi
	fi

elif [[ "${SSH_USERNAME_HOST}" == "--rmid" ]];then
	params=1
	#ID_TO_DEL${SSH_COMMAND}
	KEY_TO_DEL=${SSH_COMMAND}
	SSH_HOSTN_FILE=${KEY_TO_DEL#*@}
        SSH_HOSTN_FILE=$(echo ${SSH_HOSTN_FILE} | sed 's/ //g')
	KNOWN_HOSTS_FILE=${SSH_WORKDIR}/known_hosts
	echo -e "\nDelete host \"${SSH_HOSTN_FILE}\" from file \"${KNOWN_HOSTS_FILE}\""
	log_warning "${SSH_BASHPID}" "Delete host \"${SSH_HOSTN_FILE}\" in the known_hosts file - request from ${SSH_CONNECTUSER}" >> ${SSH_LOGFILE} 2>&1
	ssh-keygen -f ${KNOWN_HOSTS_FILE} -R ${SSH_HOSTN_FILE}

elif [[ "${SSH_USERNAME_HOST}" =~ "--" ]];then
	params=1
	echo "! Wrong parameter given!"
        print_help
fi

}

print_help()
{

echo -e "\n ----  SSHHOST little manual - supported parameters ----"
echo -e "\n user@hostname		-	Connects to a host"
echo -e " --help			-	Show this help"
echo -e " --rmkey user@hostname	-	Remove sshkey"
echo -e " --rmid hostname	-	Remove host from known-hosts"
echo -e "\n"

}

#******************************************************************************************************


program_main()
{

log "" "" >> ${SSH_LOGFILE} 2>&1
log "${SSH_BASHPID}" "*****************************************************" >> ${SSH_LOGFILE} 2>&1
log "${SSH_BASHPID}" "Connection request from host ${SSH_CONNECTUSER}, target: ${SSH_HOSTN} as user ${SSH_USERNAME}" >> ${SSH_LOGFILE} 2>&1


if [[ "${SSH_USERNAME_HOST}" == "${SSH_USERNAME}" ]];then
        echo "Wrong or no parameter given, sytax: sshh user@hostname"
	print_help
        log_error "${SSH_BASHPID}" "Wrong parameter" >> ${SSH_LOGFILE} 2>&1
        exit 1
fi

if [ "${SSH_HOSTN}" ];then
	#echo "${SSH_HOSTN}_${SSH_USERNAME}"
	SSH_FNAME="$(ls | grep -i ${SSH_HOSTN}_${SSH_USERNAME} | head -n 1)"
	if [ ! -z "${SSH_FNAME}" ] ;then
		touch "${SSH_WORKDIR}/_batch/open_conn/${SHORT_BASHPID}_${SSH_CONNECTUSER_UNDERLINE}_${SSH_USERNAME}_${SSH_HOSTN}"
		echo "${SHORT_BASHPID}" > "${SSH_WORKDIR}/_batch/open_conn/${SHORT_BASHPID}_${SSH_CONNECTUSER_UNDERLINE}_${SSH_USERNAME}_${SSH_HOSTN}"
		echo "${SSH_USERNAME_HOST}" >> "${SSH_WORKDIR}/_batch/open_conn/${SHORT_BASHPID}_${SSH_CONNECTUSER_UNDERLINE}_${SSH_USERNAME}_${SSH_HOSTN}"
		#echo " ssh -i ${SSH_WORKDIR}/config/${SSH_FNAME%*.} ${SSH_USERNAME_HOST}"
		if [[ "${SSH_COMMAND}" == "    " ]];then
			log_success "${SSH_BASHPID}" "ssh key ${SSH_FNAME} exist, connecting..." >> ${SSH_LOGFILE} 2>&1
			ssh -i ${SSH_WORKDIR}/config/"${SSH_FNAME%*.}" ${SSH_USERNAME_HOST} && $(NOW=$(date +%s); log "${SSH_BASHPID}" "Conneection closed - from ${SSH_CONNECTUSER} to ${SSH_USERNAME}@${SSH_HOSTN} - duration: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1) || $(NOW=$(date +%s); log "${SSH_BASHPID}" "Connection closed - from ${SSH_CONNECTUSER} to ${SSH_USERNAME}@${SSH_HOSTN} - duration: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1)
		else
			log_success "${SSH_BASHPID}" "ssh key ${SSH_FNAME} exist, connecting with parameters" >> ${SSH_LOGFILE} 2>&1
			ssh -i ${SSH_WORKDIR}/config/"${SSH_FNAME%*.}" ${SSH_USERNAME_HOST} "${SSH_COMMAND}" && $(NOW=$(date +%s); log "${SSH_BASHPID}" "Connection closed - from ${SSH_CONNECTUSER} to ${SSH_USERNAME}@${SSH_HOSTN} - duration: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1) || $(NOW=$(date +%s); log "${SSH_BASHPID}" "Connection closed - from ${SSH_CONNECTUSER} to ${SSH_USERNAME}@${SSH_HOSTN} - duration: $(sec_to_time NOW SSH_DATETIME)" >> ${SSH_LOGFILE} 2>&1)
		fi
		rm "${SSH_WORKDIR}/_batch/open_conn/${SHORT_BASHPID}_${SSH_CONNECTUSER_UNDERLINE}_${SSH_USERNAME}_${SSH_HOSTN}"
	else
		log_warning "${SSH_BASHPID}" "ssh keys not exist! Asking for creation" >> ${SSH_LOGFILE} 2>&1
		echo "-----> ssh keys for host '${SSH_HOSTN}' as user '${SSH_USERNAME}' don't exist!"
		read -n 1 -p "-----> -----> create? [y/n] " SSH_QUEST
		echo -e "\n"
		if [ ! "${SSH_QUEST}" == "y" ] && [ ! "${SSH_QUEST}" == "n" ];then
			log_error "${SSH_BASHPID}" "No correct answer given. Abort..." >> ${SSH_LOGFILE} 2>&1
			echo -e "\n"
			echo "-----> -----> Please press only 'y' or 'n' ! Abort..."
			echo -e "\n"
			exit 1
		else
			if [ "${SSH_QUEST}" == "y" ];then
				log "${SSH_BASHPID}" "ssh keys would be created and copied to the host" >> ${SSH_LOGFILE} 2>&1
				SSH_FNAME="id_rsa_${SSH_HOSTN}_${SSH_USERNAME}"
				echo "-----> key creation"
				ssh-keygen -t rsa -N "" -f "${SSH_FNAME}"
				echo "-----> copy files to host ${SSH_HOSTN}"

				if [ "$(ssh-copy-id -i ${SSH_WORKDIR}/config/"${SSH_FNAME}".pub "${SSH_USERNAME_HOST}")" ]; then
					log_success "${SSH_BASHPID}" "ssh keys copied" >> ${SSH_LOGFILE} 2>&1
					program_main
				else
					echo "-----> copy not succesful. Abort..."
					log_error "${SSH_BASHPID}" "ssh keys NOT copied!" >> ${SSH_LOGFILE} 2>&1
					rm ${SSH_WORKDIR}/config/"${SSH_FNAME}".pub
					rm ${SSH_WORKDIR}/config/"${SSH_FNAME}"
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
	print_help
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
check_params
if [[ ${params} -eq 0 ]];then
	program_main
fi
