#######################################################################
#################一键MYSQL服务器部署#######################################
###########################################################################
#!/bin/bash
#create mysql db01 scripts
#zuozhe cj
#time 20180413
hostname db01
/bin/sed -i 's#backup#db01#' /etc/sysconfig/network
/bin/sed -i 's#IPADDR=10.0.0.100#IPADDR=10.0.0.51#g' /etc/sysconfig/network-scripts/ifcfg-eth0
/bin/sed -i 's#IPADDR=172.16.1.100#IPADDR=172.16.1.51#g' /etc/sysconfig/network-scripts/ifcfg-eth1
############################################################################################
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
useradd -s /sbin/noligin mysql -M
mkdir –p /application/
mkdir -p /home/oldboy/tools 
cd /home/oldboy/tools/
wget http://10.0.0.61/mysql-5.5.49-linux2.6-x86_64.tar.gz
#wget https://downloads.mysql.com/archives/get/file/mysql-5.5.49-linux2.6-x86_64.tar.gz
tar zxf mysql-5.5.49-linux2.6-x86_64.tar.gz
\mv mysql-5.5.49-linux2.6-x86_64 /application/mysql-5.5.49
cd /application/mysql-5.5.49/
ln -s /application/mysql-5.5.49/ /application/mysql
chown -R mysql.mysql /application/mysql/
./scripts/mysql_install_db --basedir=/application/mysql/ --datadir=/application/mysql/data/ --user=mysql  
cd /application/mysql/bin
/bin/sed -i 's#/usr/local/#/application/#g' mysqld_safe 
cd ..
/bin/sed -i 's#/usr/local/#/application/#g' support-files/mysql.server
\cp support-files/mysql.server /etc/init.d/mysqld  
chmod +x /etc/init.d/mysqld 
\cp support-files/my-small.cnf /etc/my.cnf
/application/mysql/bin/mysqld_safe --user=mysql &
PATH="/application/mysql/bin:$PATH"
echo "PATH="/application/mysql/bin:$PATH"" >>/etc/profile
. /etc/profile
lsof -i :3306
/etc/init.d/mysqld stop
chkconfig mysqld on

#######################################################################################
#例子-创建wordpress博客数据库##可以手动或自动建库，要自动请取消前面注释
#mysqladmin -u root password 'zchx123'
#mysql -uroot -pzchx123
#create database wordpress;
#grant all on wordpress.* to wordpress@'localhost' identified by '123456';
#grant all on wordpress.* to wordpress@'172.16.1.%' identified by '123456';
#flush privileges;
###########################################################################
###以下只在web服务器创建
#echo -e "<?php\n
#  \$link_id=mysql_connect('db01.51cto.com','wordpress','123456') or mysql_error();\n
#     if(\$link_id) {\n
#            echo \"mysql successful by cj wordpress\";\n
#     }\n
#    else{\n
#             echo mysql_error();\n
#     }\n
#?>"|egrep -v "^$" >/application/nginx/html/blog/test_mysql.php
