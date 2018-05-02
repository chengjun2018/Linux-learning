#!/bin/bash
#One key deploys the rsync server.
#zuozhe cj
#time 20180402
#linux优化部分#
#mkdir -p /server/scripts/
echo “>/etc/udev/rules.d/70-persistent-net.rules” >>/etc/rc.local
##############################################################
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
hostname backup
sed -i 's#HOSTNAME=oldboy#HOSTNAME=backup#' /etc/sysconfig/network
cat >>/etc/hosts<<EOF
172.16.1.5   lb01 www.51cto.com   51cto.com  bbs.51cto.com  status.51cto.com blog.51cto.com
172.16.1.6   lb02 www.51cto.com   51cto.com  bbs.51cto.com  status.51cto.com blog.51cto.com
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
#rsync服务端配置/etc/rsyncd.conf文件#
echo -e "##rsyncd.conf start##\n
uid = rsync\n
gid = rsync\n
use chroot = no\n
maxconnections = 300\n
timeout = 300\n
pid file = /var/run/rsyncd.pid\n
lock file = /var/run/rsyncd.lock\n
log file = /var/log/rsyncd.log\n
[backup]\n
path = /backup/\n
ignore errors\n
read only = false\n
list = false\n
hosts allow = 172.16.1.0/24\n#host deny = 0.0.0.0/32\nauth users = rsync_backup\n
secrets file = /etc/rsync.password\n
[nfsbackup]\n
path = /nfsbackup/\n
ignore errors\n
read only = false\n
list = false\n
hosts allow = 172.16.1.0/24\n#host deny = 0.0.0.0/32\nauth users = rsync_backup\n
secrets file = /etc/rsync.password\n
#rsync_config______________end" >rsync.txt && grep -v "^$" rsync.txt >/etc/rsyncd.conf
#添加用户并启动rsync且加入开机自启动 
useradd rsync -s /sbin/nologin -M
/usr/bin/rsync --daemon
echo "/usr/bin/rsync --daemon" >>/etc/rc.local
mkdir -p /backup
mkdir -p /nfsbackup
mkdir -p /home/oldboy/tools/
mkdir -p /home/oldboy/scripts/
mkdir -p /home/oldboy/application/
chown -R oldboy.oldboy /home/oldboy/tools/ /home/oldboy/scripts/ /home/oldboy/application/
chown  rsync.rsync /backup/ /nfsbackup/
echo "rsync_backup:oldboy" >/etc/rsync.password
chmod 600 /etc/rsync.password
#添加备份检查及邮件通知and删除过期备份
echo -e "#\!/bin/bash\n
##md5sum flag Key and mail to 278028843\n
#zuozhe\n
#time-20180329\n
IP=\$(ifconfig eth1|awk -F \"[ :]+\" 'NR==2{print \$4}')\n
Path=\"/backup/\"\n
if [ \$(date +%w) -eq 0 ]
then
   Time=week_\$(date +%F_%w -d "-1day")
else
   Time=\$(date +%F -d "-1day")
fi
LANG=en
find \$Path  -type f -name \"*\${Time}*.log\"|xargs md5sum -c >>\$Path/mail_cj_\${Time}.log 2>&1
#mail to administrator
mail -s \"\$Time  back\" 278028843@qq.com <\$Path/mail_cj_\${Time}.log
##del 180 day and by saturday data  
/bin/find /backup/ -type f -mtime +180  ! -name \"*week*_6*\"|xargs rm -f"|grep -v "^$" >/server/scripts/chback.sh
echo -e "#chback data\n00 00 * * * /bin/sh /server/scripts/chback.sh >/dev/null 2>&1">>/var/spool/cron/root
cd /server/scripts/
chmod +x chback.sh
#配置邮件发送通知
echo -e "set from=cjun1986@163.com smtp=smtp.163.com smtp-auth-user=om smtp-auth-user=cjun1986 smtp-auth-password=chengjun1986 smtp-auth=login" >>/etc/mail.rc
who
###############################################
#nfs客户端rpc安装配置
yum install -y tree dos2unix nc nmap nfs-utils rpcbind
LING=en
/etc/init.d/rpcbind start
chkconfig rpcbind on
mkdir -p /data
echo "/etc/init.d/rpcbind start" >>/etc/rc.local
#mount -t nfs 172.16.1.31:/data /mnt
#echo "/bin/mount -t nfs 172.16.1.31:/data /mnt/" >>/etc/rc.local
#groupadd zuma -g 888
#useradd zuma -u 888 -g zuma
#mount -t nfs 172.16.1.31:/oldboy /home
#echo "/bin/mount -t nfs 172.16.1.31:/oldboy /home/" >>/etc/rc.local
#umount -lf /home
sed -ir '13 iPort 52113\nPermitRootLogin no\nPermitEmptyPasswords no\nUseDNS no\nGSSAPIAuthentication no' /etc/ssh/sshd_config
#####
su - oldboy
df -HP



