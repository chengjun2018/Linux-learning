#!/bin/sh
. /etc/init.d/functions
#1.product key pair
ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa >/dev/null 2>&1
 if [ $? -eq 0 ];then
    action "create dsa $ip" /bin/true
 else
    action "create dsa $ip" /bin/false
    exit 1
 fi

#2.dis pub key
for ip in 8 31 41 
do
 expect fenfa_sshkey.exp ~/.ssh/id_dsa.pub 172.16.1.$ip >/dev/null 2>&1
 if [ $? -eq 0 ];then
    action "$ip" /bin/true
 else
    action "$ip" /bin/false
 fi
done
#3.dis fenfa scripts
for n in 8 31 41
do
 scp -P 52113 -rp ~/scripts oldboy888@172.16.1.$n:~
done

#4.install service
for m in 8 31 41
do
 ssh -t -p 52113 oldboy888@172.16.1.$m sudo /bin/bash ~/scripts/install.sh
done
