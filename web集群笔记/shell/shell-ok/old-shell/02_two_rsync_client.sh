#!/bin/bash
#One key deploys the rsync server.
#zuozhe cj
#time 20180402
#配置使用内部YUM仓库172.16.1.61 conf/etc/yum.repos.d/yum.repo####
/bin/echo -e "[yum]\n
name=Server\n
baseurl=http://10.0.0.61\n
enable=1\n
gpgcheck=0"|egrep -v "^$" >/etc/yum.repos.d/yum.repo
/bin/sed -i '18a enabled=0' /etc/yum.repos.d/CentOS-Base.repo
/bin/sed -i '26a enabled=0' /etc/yum.repos.d/CentOS-Base.repo
/bin/sed -i '34a enabled=0' /etc/yum.repos.d/CentOS-Base.repo
yum --enablerepo=yum --disablerepo=base,extras,updates,epel list
####################################################################
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
mkdir -p /nfsbackup/
mkdir -p /home/oldboy/tools/
mkdir -p /home/oldboy/scripts/
mkdir -p /home/oldboy/application/
chown -R oldboy.oldboy /home/oldboy/tools/ /home/oldboy/scripts/ /home/oldboy/application/
chown  rsync.rsync /backup/ /nfsbackup/
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
find \$BK -type f -name "*\$Time.tar.gz"|xargs md5sum >>\$Path/flag_\$Time.log\n
cd \$BK\n
/usr/bin/rsync  -az \$BK rsync_backup@172.16.1.41::backup/ --password-file=/etc/rsync.password\n
/bin/find \$BK -type f -mtime +7 \( -name "*.log" -o -name "*.tar.gz" \)|xargs rm -f " |grep -v "^$" >bk_rsync.sh
chmod +x bk_rsync.sh
echo -e "#backup WebServer /var/www/html and rsync to BackupServer\n*/1 * * * * /bin/sh /server/scripts/bk_rsync.sh >/dev/null 2>&1" >>/var/spool/cron/root
who
#################################################
#NFS服务端配置
yum install -y tree dos2unix nc nmap nfs-utils rpcbind
LING=en
/etc/init.d/rpcbind start
/etc/init.d/nfs start
id nfsnobody
chkconfig nfs on
chkconfig rpcbind  on
#peizhi/etc/exports file
echo -e "#share /data/ by cj for zhangkun at 20180329\n/data  172.16.1.0/24(rw,sync)" >>/etc/exports
chown -R nfsnobody.nfsnobody /data
/etc/init.d/rpcbind reload
/etc/init.d/nfs reload
rpcinfo -p localhost
exportfs -rv
showmount -e 172.16.1.31
echo "/etc/init.d/rpcbind start" >>/etc/rc.local
echo "/etc/init.d/nfs start" >>/etc/rc.local
#多用户配置实例
#groupadd zuma -g 888
#useradd zuma -u 888 -g zuma
#mkdir /oldboy -p
#chown -R zuma.zuma /oldboy/
#echo "/oldboy 172.16.1.31/24(rw,sync,all_squash,anonuid=888,anongid=888)" >>/etc/exports
#/etc/init.d/nfs reload
#showmount -e 172.16.1.31
#服务端NFS内核优化
cat /etc/sysctl.conf <<EOF
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.wmem_max = 16777216
net.core.rmem_max = 16777216
EOF
sysctl -p
#inotify+rsync配置
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
yum install -y  inotify-tools
#inotifywait -mrq --timefmt '%d/%m/%y %H:%M' --format '%T %w%f' -e close_write,create,delete /backup/ >>/inotify.log
echo -e "#\!/bin/bash\n
#The is inotify and rsync dir by shell\n
#zuozhe cj\n
#time 20180401\n
IP=172.16.1.41\n
Path=/nfsbackup/\n
/usr/bin/inotifywait -mrq  --format '%w%f' -e close_write,delete \$Path\n
|while read file\n
do\n
   cd \$Path\n
if [ -f \$file ];then\n
   rsync -az \$file --delete rsync_backup@\$IP::nfsbackup/ --password-file=/etc/rsync.password\n
else\n
   cd \$Path &&\n
rsync -az ./ --delete rsync_backup@\$IP::nfsbackup/ --password-file=/etc/rsync.password\n
   fi\n
  done"|grep -v "^$" >/server/scripts/inotify_rsync.sh
cd /server/scripts/
chmod +x inotify_rsync.sh
echo -e "#The is inotify and rsync dir by shell\n* * * * * /bin/sh  /server/scripts/inotify_rsync.sh" >>/var/spool/cron/root
#inotify调优
echo “50000000” >/proc/sys/fs/inotify/max_user_watches
echo “50000000” >/proc/sys/fs/inotify/max_queued_events
#inotify+sersync实时同步配置-在nfs01实现
mkdir -p /application
#cd application/
#上传文件到/application目录下
/bin/tar -zxf /home/oldboy/tools/sersync_conf_2018-04-01.tar.gz -C /application/
chmod +x /application/sersync/bin/sersync
/application/sersync/bin/sersync -d -r -n 8 -o /application/sersync/conf/confxml.xml
echo  "/application/sersync/bin/sersync -d -r -n 8 -o /application/sersync/conf/confxml.xml" >>/etc/rc.local
#cd ..
#/bin/tar -zxf tools/sersync_conf_2018-04-01.tar.gz -C application/
#chmod +x application/sersync/bin/sersync
#/home/oldboy/application/sersync/bin/sersync -d -r -n 8 -o /home/oldboy/application/sersync/conf/confxml.xml
#echo  "/home/oldboy/application/sersync/bin/sersync -d -r -n 8 -o  /home/oldboy/application/sersync/conf/confxml.xml" >>/etc/rc.local
sed -ir '13 iPort 52113\nPermitRootLogin no\nPermitEmptyPasswords no\nUseDNS no\nGSSAPIAuthentication no' /etc/ssh/sshd_config
#####
su - oldboy
df -HP

