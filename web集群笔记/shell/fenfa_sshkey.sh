#!/bin/bash
#
#
#
. /etc/init.d/functions
for ip in 8 31 41
do
 expect fenfa_sshkey.exp ~/.ssh/id_dsa.pub 172.16.1.$ip >/dev/null 2>&1
 if [ $? -eq 0 ];then
   action "$ip" /bin/true
 else
   action "$ip" /bin/false
 fi
done
