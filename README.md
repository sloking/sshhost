# sshhost

## Set up the host

1. Create a virtual Machine with an Linux like Ubuntu or so
2. Set static ip, set hostname (e.g. sshhost)
3. Create a user with a strong password
4. Copy the files in ssh to .ssh in user home


## Set up your machine

#####1. create ssh keys for connection to sshhost
 - ssh-keygen -t rsa -b 4096

#####2. copy the key to sshhost
 - ssh-copy-id -i /home/myusername/.ssh/id_rsa_sshhost.pub user@sshhost

#####3. test it
 - ssh -i /home/myusername/.ssh/id_rsa_sshhost user@sshhost

#####4. create some aliases in file .bash_aliases or /etc/bash/bashrc or wathever you bash loaded
 - sshh='ssh -t -t -i ~/.ssh/id_rsa_sshhost user@sshhost "bash /home/user/.ssh/_batch/dossh.sh"'
 - sshhost='ssh -i ~/.ssh/id_rsa_sshhost root@sshhost'
 - sshhostlog='ssh -i ~/.ssh/id_rsa_sshhost root@sshhost tail -f -n 100 /home/user/.ssh/log/sshconnect.log'
 - sshhostopenconn='ssh -t -t -i ~/.ssh/config/id_rsa_sshhost root@sshhost bash /home/user/watch_dir.sh'

#####5. connect to an host with the new command 'sshh'
 - sshh root@host1
 
at first connection it will ask you for key creation...

#####6. in an other terminal look for logfile or openconnections
 - sshhostlog
 - sshhostopenconn


Feel free to inform me, when you find any mistakes or changes...
sloking@gmx.net

