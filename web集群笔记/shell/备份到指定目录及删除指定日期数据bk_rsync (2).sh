#!/bin/bash
#the is web server backup /var/www/html to /backup
#zuozhe cj
#time 20180328 
IP=$(ifconfig eth1|awk -F "[ :]+" 'NR==2{print $4}')
HT="/var/www/"
BK="/backup/"
Time=$(date +%F)
Path="/backup/$IP"
if [ $(date +%w) -eq 0 ]
then
   Time=week_$(date +%F_%w -d "-1day")
else 
   Time=$(date +%F -d "-1day")
fi
[ ! -d $Path ]  &&  mkdir $BK/$IP -p
############################################################
#backup /www/html/ by data to /backup/#######################
cd $HT
/bin/tar zcf $Path/html_$Time.tar.gz ./html/ &&\
#检查打包是否正确########################################### 
find $BK -type f -name "*$Time.tar.gz"|xargs md5sum >>$Path/flag_$Time.log
#Rsync to BackupServer##################################
cd $BK
/usr/bin/rsync  -az $BK rsync_backup@172.16.1.41::backup/ --password-file=/etc/rsync.password
## delete +7 day by data ########################################
/bin/find $BK -type f -mtime +7 \( -name "*.log" -o -name "*.tar.gz" \)|xargs rm -f

