# sshhost

## Wait, What?!
sshhost is an bash script for relay ssh connection over an specific host.
This host do the connection via ssh with keys and have for each host an own key.
So if you have 100 people and everyone will connect to 100 different host, you don't need to create 100*100 keys.
Set up the following and you need **only one sshhost**.




### Set up the sshhost host

##### 1. Create a virtual Machine (or install native) with an Linux like Ubuntu or so
##### 2. Set static ip, set hostname (in this case sshhost)
##### 3. Create a user with a strong password
##### 4. Copy the folder/files in folder ssh to .ssh in users home directory


### Set up your machine

##### 1. create ssh keys for connection to sshhost
 - ssh-keygen -t rsa -N "" -f /home/myusername/.ssh/id_rsa_sshhost

##### 2. copy the key to sshhost
 - ssh-copy-id -i /home/myusername/.ssh/id_rsa_sshhost.pub user@sshhost

##### 3. test it
 - ssh -i /home/myusername/.ssh/id_rsa_sshhost user@sshhost

##### 4. create some aliases in your own file .bash_aliases or /etc/bash/bashrc or wathever you bash loaded
 - sshh='ssh -t -t -i ~/.ssh/id_rsa_sshhost user@sshhost "bash /home/user/.ssh/_batch/dossh.sh"'
 - sshhost='ssh -i ~/.ssh/id_rsa_sshhost user@sshhost'
 - sshhostlog='ssh -i ~/.ssh/id_rsa_sshhost root@sshhost tail -f -n 100 /home/user/.ssh/log/sshconnect.log'
 - sshhostopenconn='ssh -t -t -i ~/.ssh/config/id_rsa_sshhost root@sshhost bash /home/user/.ssh/_batch/watch_dir.sh'

##### 5. connect to an host with the new command 'sshh'
 - sshh root@host1
 
at first connection it will ask you for key creation...

##### 6. in an other terminal look for logfile or openconnections
 - sshhostlog
 - sshhostopenconn


Feel free to inform me, when you find any mistakes or changes...
sloking@gmx.net

If you want to use outputs and logs in german, rename file dossh_ger.sh to dossh.sh
