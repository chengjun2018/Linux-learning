#!/bin/bash
#One key deploys the rsync server.
#zuozhe cj
#time 20180402
hostname nfs01
sed -i 's#HOSTNAME=oldboy#HOSTNAME=nfs01#' /etc/sysconfig/network
cat >>/etc/hosts<<EOF
172.16.1.5   lb01
172.16.1.6   lb02
172.16.1.7   web02
172.16.1.8   web01
172.16.1.51  db01
172.16.1.31  nfs01
172.16.1.41  backup
172.16.1.61  m01
EOF
sed -i 's#SELINUX=enforcing#SELINUX=disabled#' /etc/selinux/config
setenforce 0
chkconfig --list |grep 3:on|awk '{print "chkconfig",$1,"off" }' |bash
chkconfig --list |grep 3:off|egrep  "crond|sshd|network|ntpdate|rsyslog|sysstat" |awk '{print"chkconfig",$1,"on"}'
chkconfig --list |grep 3:off|egrep  "crond|sshd|network|rsyslog|sysstat|ntpdate" |awk '{print"chkconfig",$1,"on"}' |bash
service  ntpdate  start
echo -e "#Synchronize every half hour.\n*/30 * * * * /usr/sbin/ntpdate time.twc.weather.com >/dev/null 2>&1" >>/var/spool/cron/root
useradd  oldboy
echo "123456"|passwd --stdin oldboy
\cp /etc/sudoers /etc/sudoers.ori
echo "oldboy    ALL=(ALL)    NOPASSWD: ALL" >>/etc/sudoers
tail -1 /etc/sudoers
visudo  -c
cp /etc/sysconfig/i18n /etc/sysconfig/i18n.ori
echo 'LANG="zh_CN.UTF-8"' >/etc/sysconfig/i18n
source /etc/sysconfig/i18n
echo "oldboy" >/etc/rsync.password
chmod 600 /etc/rsync.password
mkdir /backup/ -p
mkdir /var/www/html/ -p
touch /var/www/html/html{1..100}.txt
#测试rsync是否有效-在客户端/backup/下创建文件后去backup-Rsync服务端/backup下观察是否有数据
#cd /backup/
#touch std{1..30}
#rsync -az /backup/ rsync://rsync_backup@172.16.1.41::backup/ --password-file=/etc/rsync.password
#scripts
cd /server/scripts/
echo -e "#\!/bin/bash\n
#the is web server backup /var/www/html to /backup\n
#zuozhe cj\n
#time 20180328\n
IP=\$(ifconfig eth1|awk -F \"[ :]+\" 'NR==2{print \$4}')\n
HT=\"/var/www/\"\n
BK=\"/backup/\"\n
Time=\$(date +%F)\n
Path=\"/backup/\$IP\"\n
if [ \$(date +%w) -eq 0 ]\n
then\n
    Time=\$(date +%F -d "-1day")\n
else\n
   Time=\$(date +%F -d "-1day")\n
fi\n
[ ! -d \$Path ]  &&  mkdir \$BK/\$IP -p\n
LANG=en\n
cd \$HT\n
/bin/tar zcf \$Path/html_\$Time.tar.gz ./html/ &&\n
find \$BK -type f -name \"*\$Time.tar.gz\"|xargs md5sum >>\$Path/flag_\$Time.log\n
cd \$BK\n
/usr/bin/rsync  -az \$BK rsync_backup@172.16.1.41::backup/ --password-file=/etc/rsync.password\n
/bin/find \$BK -type f -mtime +7 \( -name \"*.log\" -o -name \"*.tar.gz\" \)|xargs rm -f" |grep -v "^$" >bk_rsync.sh
chmod +x bk_rsync.sh
echo -e "#backup WebServer /var/www/html and rsync to BackupServer\n00 00 * * * /bin/sh /server/scripts/bk_rsync.sh >/dev/null 2>&1" >>/var/spool/cron/root
who
