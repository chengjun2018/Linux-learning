#!/bin/bash
#create LNMP scripts
#zuozhe cj
#time 20180418
hostname web02
/bin/sed -i 's#backup#web02#' /etc/sysconfig/network
/bin/sed -i 's#IPADDR=10.0.0.100#IPADDR=10.0.0.7#g' /etc/sysconfig/network-scripts/ifcfg-eth0
/bin/sed -i 's#IPADDR=172.16.1.100#IPADDR=172.16.1.7#g' /etc/sysconfig/network-scripts/ifcfg-eth1
##########################################################################################
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
sleep 3
yum install zlib zlib-devlel  gcc openssl-devel -y
sleep 3
yum install gcc nfs-utils rpcbind  -y 
sleep 3
yum install -y  zlib-devel libxml2-devel libjpeg-devel libjpeg-turbo-devel libiconv-devel freetype-devel libpng-devel gd-devel libxslt-devel libmcrypt-devel
sleep 3
yum install -y mcrypt  mhash
sleep 3
####################################################################
useradd -s /sbin/noligin mysql -M
useradd -u 502 -s /sbin/nologin -M www
mkdir -p /home/oldboy/tools
mkdir -p /application/
mkdir -p /data/nfs-blog
mkdir -p /server/scripts/
##########################################################################
####Mysql数据库部署#######################################################
##########################################################################
cd /home/oldboy/tools/
wget http://10.0.0.61/mysql-5.5.49-linux2.6-x86_64.tar.gz
tar zxf mysql-5.5.49-linux2.6-x86_64.tar.gz
mv mysql-5.5.49-linux2.6-x86_64 /application/mysql-5.5.49
cd /application/mysql-5.5.49/
ln -s /application/mysql-5.5.49/ /application/mysql
chown -R mysql.mysql /application/mysql/
./scripts/mysql_install_db --basedir=/application/mysql/ --datadir=/application/mysql/data/ --user=mysql  
cd /application/mysql/bin
sed -i 's#/usr/local/#/application/#g' mysqld_safe 
cd ..
sed -i 's#/usr/local/#/application/#g' support-files/mysql.server
cp support-files/mysql.server /etc/init.d/mysqld  
chmod +x /etc/init.d/mysqld 
\cp support-files/my-small.cnf /etc/my.cnf
/application/mysql/bin/mysqld_safe --user=mysql &
PATH="/application/mysql/bin:$PATH"
echo "PATH="/application/mysql/bin:$PATH"" >>/etc/profile
. /etc/profile
lsof -i :3306
/etc/init.d/mysqld stop
chkconfig mysqld on
###########################################################
##部署apache###############################################
###########################################################
cd /home/oldboy/tools
wget http://10.0.0.61/httpd-2.2.31.tar.gz
sleep 3
tar zxf httpd-2.2.31.tar.gz
cd httpd-2.2.31 &&\
./configure --prefix=/application/apache2.2.31 --enable-deflate --enable-expires --enable-headers --enable-modules=most --enable-so --with-mpm=worker --enable-rewrite
make && make install
####
ln -s /application/apache2.2.31/ /application/apache
sleep 3
chown -R www.www /application/apache/htdocs/blog/
cd /application/apache/htdocs/
mkdir www blog bbs
###修改配置文件，让其支持PHP解析
cd /application/apache/conf/
/bin/sed -i 's#\#User daemon#User www#g' /application/apache/conf/httpd.conf
/bin/sed -i 's#\#Group daemon#User www#g' /application/apache/conf/httpd.conf
/bin/sed -i 's#\#Include conf/extra/httpd-vhosts.conf#Include conf/extra/httpd-vhosts.conf#g' /application/apache/conf/httpd.conf
/bin/sed -i 's#ServerName locahost:80#ServerName 127.0.0.1:80#' /application/apache/conf/httpd.conf
/bin/sed -i 's#Options Indexes FollowSymLinks#Options -Indexes FollowSymLinks#g' /application/apache/conf/httpd.conf
/bin/sed -i '312a AddHandler php5-script php' /application/apache/conf/httpd.conf
/bin/sed -i '313a AddType application/x-httpd-php .php. phtml' /application/apache/conf/httpd.conf
/bin/sed -i '314a AddType application/x-httpd-php-source .phps' /application/apache/conf/httpd.conf
sleep 3
##############
cd /application/apache/conf/extra/
echo -e "NameVirtualHost *:80\n
<VirtualHost *:80>\n
    ServerAdmin 278028843@qq.com\n
    DocumentRoot \"/application/apache2.2.31/htdocs/www\"\n
    ServerName www.51cto.com\n
    ServerAlias 51cto.com\n
    ErrorLog \"logs/www-error_log\"\n
    CustomLog \"logs/www-access_log\" common\n
</VirtualHost>\n
<VirtualHost *:80>\n
    ServerAdmin 278028843@qq.com\n
    DocumentRoot \"/application/apache2.2.31/htdocs/blog\"\n
    ServerName blog.51cto.com\n
    ErrorLog \"logs/blog-error_log\"\n
    CustomLog \"logs/blog-access_log\" common\n
</VirtualHost>\n
<VirtualHost *:80>\n
    ServerAdmin 278028843@qq.com\n
    DocumentRoot \"/application/apache2.2.31/htdocs/bbs\"\n
    ServerName bbs.51cto.com\n
    ErrorLog \"logs/bbs-error_log\"\n
    CustomLog \"logs/bbs-access_log\" common\n
</VirtualHost>"|egrep -v "^$" >httpd-vhosts.conf
########################################################
/application/apache/bin/apachectl -t
/application/apache/bin/apachectl graceful
########################################################
###########PHP部署#####################################
######################################################
#更新bash源
#wget -O /etc/yum.repos.d/CentOS-Base.repo  http://mirrors.aliyun.com/repo/Centos-6.repo
#更新epel源
#wget -O /etc/yum.repos.d/epel.repo  http://mirrors.aliyun.com/repo/epel-6.repo
#安装基础库及程序
cd /etc/yum.repos.d/
mkdir tmp -p
mv CentOS-Base.repo CentOS-Debuginfo.repo CentOS-fasttrack.repo CentOS-Media.repo CentOS-Vault.repo yum.repo  tmp/
wget -O /etc/yum.repos.d/CentOS-Base.repo  http://mirrors.aliyun.com/repo/Centos-6.repo
wget -O /etc/yum.repos.d/epel.repo  http://mirrors.aliyun.com/repo/epel-6.repo
yum install libcurl-devel -y
sleep 5
rm -rf CentOS-Base.repo epel.repo 
mv tmp/* .
sleep 3
rpm -qa zlib-devel libxml2-devel libjpeg-devel libjpeg-turbo-devel libiconv-devel freetype-devel libpng-devel gd-devel libcurl-devel libxslt-devel libmcrypt-devel  mcrypt  mhash openssl openssl-devel
sleep 3
#yum install -y  zlib-devel libxml2-devel libjpeg-devel libjpeg-turbo-devel libiconv-devel freetype-devel libpng-devel gd-devel libcurl-devel libxslt-devel libmcrypt-devel  mcrypt  mhash openssl openssl-devel
#####安装基础库-编译安装
cd /home/oldboy/tools/
wget http://10.0.0.61/libiconv-1.14.tar.gz
tar xf libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=/usr/local/libiconv
make && make install
#######################
#####安装编译PHP#######
#######################
cd /home/oldboy/tools/
wget http://10.0.0.61/php-5.3.27.tar.xz
tar xf php-5.3.27.tar.xz
cd php-5.3.27
./configure --prefix=/application/php5.3.27 --with-mysql=mysqlnd --with-pdo-mysql=mysqlnd --with-apxs2=/application/apache/bin/apxs --with-openssl --with-zlib --with-freetype-dir --with-jpeg-dir --with-png-dir --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl --enable-pcntl --enable-sockets --with-xmlrpc --enable-soap --enable-short-tags --enable-zend-multibyte --enable-static --with-xsl --enable-ftp 
sleep 3
make && make install
sleep 3
ln -s /application/php5.3.27/ /application/php
###################################################
#php测试文件
cd /application/apache/htdocs/blog/
echo -e "<?php\n
phpinfo():\n
?>"|egrep -v "^$" >test_info.php
#数据库连接测试文件
echo -e "<?php\n
  \$link_id=mysql_connect('db01.51cto.com','wordpress','123456') or mysql_error();\n
     if(\$link_id) {\n
             echo \"mysql successful by cj wordpress\";\n
     }\n
     else{\n
             echo mysql_error();\n
     }\n
?>"|egrep -v "^$" >test_mysql.php
#####################################################
##Wordpress 博客#####数据恢复####
#cd /home/oldboy/tools
#/bin/tar xf blog.tar.gz
#\mv blog/*  /application/apache/htdocs/blog/
#chown -R www.www /application/apache/htdocs/blog/
#
########################################################
/application/apache/bin/apachectl -t
sleep 5
/application/apache/bin/apachectl graceful
########################################################
#配置挂载NFS空间##
#/etc/init.d/rpcbind start
#/bin/echo "/etc/init.d/rpcbind start" >> /etc/rc.local
#/bin/mount -t nfs 172.16.1.31:/data/nfs-blog /application/apache/htdocs/blog/wp-content/uploads
#/bin/echo "/bin/mount -t nfs 172.16.1.31:/data/nfs-blog /application/apache/htdocs/blog/wp-content/uploads/" >>/etc/rc.local
###检查挂载效果
df -HP

