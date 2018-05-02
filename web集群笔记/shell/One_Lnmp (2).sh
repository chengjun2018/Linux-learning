#!/bin/bash
#create LNMP scripts
#zuozhe cj
#time 20180413
#######################################################################
#################一键MYSQL服务器部署#######################################
###########################################################################
#hostname db01
#sed -i 's#backup#db01#' /etc/sysconfig/network
useradd -s /sbin/noligin mysql -M
mkdir –p /application/
mkdir -p /home/oldboy/tools 
cd /home/oldboy/tools/
wget https://downloads.mysql.com/archives/get/file/mysql-5.5.49-linux2.6-x86_64.tar.gz
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
echo -e "<?php\n
          $link_id=mysql_connect('localhost','root','oldboy123') or mysql_error();\n
          if($link_id){\n
                   echo "mysql successful by oldboy !";\n
          }else{\n
                   echo mysql_error();\n
          }\n
?>"|egrep -v "^$" >/application/nginx/html/blog/test_mysql.php
#######################################################################################
#例子-创建wordpress博客数据库##可以手动或自动建库，要自动请取消前面注释
#mysqladmin -u root password 'zchx123'
#mysql -uroot -pzchx123
#create database wordpress;
#grant all on wordpress.* to wordpress@'localhost' identified by '123456';
#flush privileges;
#########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################
############一键部署php###################################################################################################################################################################
##########################################################################################################################################################################################
##yum安装php依赖库
#更新bash源
wget -O /etc/yum.repos.d/CentOS-Base.repo  http://mirrors.aliyun.com/repo/Centos-6.repo
#更新epel源
wget -O /etc/yum.repos.d/epel.repo  http://mirrors.aliyun.com/repo/epel-6.repo
yum install -y  zlib-devel libxml2-devel libjpeg-devel libjpeg-turbo-devel libiconv-devel freetype-devel libpng-devel gd-devel libcurl-devel libxslt-devel libmcrypt-devel  mcrypt  mhash
cd /home/oldboy/tools/
wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=/usr/local/libiconv
make &&make install
rpm -qa zlib-devel libxml2-devel libjpeg-devel libjpeg-turbo-devel libiconv-devel freetype-devel libpng-devel gd-devel libcurl-devel libxslt-devel libmcrypt-devel  mcrypt  mhash
##上传php-5.5.32.tar.gz包到/home/oldboy/tools/
wget http://mirrors.sohu.com/php/php-5.5.32.tar.gz
tar zxf php-5.5.32.tar.gz
cd php-5.5.32
./configure \
--prefix=/application/php5.5.32 \
--with-mysql=/application/mysql \
--with-icobv-dir=/usr/local/libiconv \
--with-freetype-dir \
--with-jpeg-dir \
--with-png-dir \
--with-zlib \
--with-libxml-dir=/usr \
--enable-xml \
--disable-rpath \
--enable-safe-mode \
--enable-bcmath \
--enable-shmop \
--enable-sysvsem \
--enable-inline-optimization \
--with-curl \
--with-curlwrappers \
--enable-mbregex \
--enable-fpm \
--enable-mbstring \
--with-mcrypt \
--with-gd \
--enable-gd-native-ttf \
--with-openssl \
--with-mahsh \
--enable-pcntl \
--enable-sockets \
--with-xmlrpc \
--enable-zip \ 
--enable-soap \
--enable-short-tags \
--enable-zend-multibyte \
--enable-static \
--with-xsl \
--with-fpm-user=www \
--with-fpm-group=www \
--enable-ftp \
--enable-opcache=no
ln -s /application/mysql/lib/libmysqlclient.so.18 /usr/lib64/
touch ext/phar/phar.phar
make && make install
#php测试页
echo "<?php phpinfo(); ?>" >/application/nginx/html/blog/test_info.php
ln -s /application/php5.5.32/ /application/php
cp php.ini-production /application/php/lib/php.ini
cd /application/php/etc/
cp php-fpm.conf.default php-fpm.conf
/application/php/sbin/php-fpm
who
################################################################################################################################################################
################################################################################################################################################################
##############一键Nginx部署#####################################################################################################################################
################################################################################################################################################################
#!/bin/bash
yum install pcre pcre-devel openssl-devel -y
useradd www -s /sbin/nologin -M
mkdir -p /home/data/
mkdir -p /application/
cd /home/data/
wget -q http://nginx.org/download/nginx-1.6.3.tar.gz
tar xf nginx-1.6.3.tar.gz
cd nginx-1.6.3
./configure --user=www --group=www --prefix=/application/nginx1.6.3 --with-http_stub_status_module --with-http_ssl_module
make && make install
ln -s /application/nginx-1.6.3/ /application/nginx
/application/nginx/sbin/nginx
/bin/mkdir -p /application/nginx/conf/extra
/bin/mkdir -p /application/nginx/html/{blog,www}
echo "blog" > /application/nginx/html/blog/index.html
echo "www" > /application/nginx/html/www/index.html
cd /application/nginx/conf
#编写www配置文件
echo -e "server {\n
        listen       80;\n
       server_name  www.51cto.com 51cto.com;\n
       location / {\n
        root  html/www;\n
        index index.html index.html;\n
		rewrite ^/(.*) http://www.51cto.com/$1 permanent;\n
        access_log logs/www_access.log main gzip buffer=32k flush=5s;\n
       }\n
       location ~.*\.(php|php5)?$ {\n
            root   html/www;\n
            fastcgi_pass 127.0.0.1:9000;\n
            fastcgi_index  index.php;\n
            include fastcgi.conf;\n
        }\n
 }"|egrep -v "^$" >extra/www.conf
#编写blog配置文件带静态化
echo -e "server {\n
        listen       80;\n
        server_name  blog.51cto.com;\n
        root   html/blog;\n
        index index.php index.html index.htm;\n
        access_log logs/blog_access.log;\n
location /{\n
       if ( -f $request_filename/index.html){\n
            rewrite (.*) $1/index.html break;\n
       }\n
       if (-f $request_filename/index.php){\n
            rewrite (.*) $1/index.php;\n
       }\n
       if ( find null/ -type d  $request_filename){\n
            rewrite (.*) /index.php;\n
       }\n
     }\n
location ~ .*\.(php|php5)?$ {\n
            root   html/blog;\n
            fastcgi_pass 127.0.0.1:9000;\n
            fastcgi_index  index.php;\n
            include fastcgi.conf;\n
     }\n
}"|egrep -v "^$" >extra/blog.conf
#配置监控状态
echo -e "server {\n
        listen       80;\n
        server_name  status.51cto.com;\n
        location / {\n
            stub_status on;\n
            access_log off;\n
     }\n
}"|egrep -v "^$" >extra/status.conf
#备份配置文件
cp nginx.conf nginx.conf_$(date +%F)
#优化主配置文件
echo -e "worker_processes  1;\n
events {\n
    worker_connections  1024;\n
}\n
http {\n
    include       mime.types;\n
    default_type  application/octet-stream;\n
    sendfile        on;\n
    keepalive_timeout  65;\n
    include  extra/*.conf;\n
    include  extra/index.conf;\n
    include  extra/www.conf;\n
    include  extra/blog.conf;\n
    include  extra/bbs.conf;\n
}"|egrep -v "^$" >nginx.conf
#nginx日志切割脚本
echo -e "#\!/bin/bash\n
DR="/application/nginx/logs/"\n
IP=172.16.1.41\n
cd \$DR &&\\\  
mv www_access.log www_access_$(date +%F -d -1day).log\n
mv blog_access.log blog_access_$(date +%F -d -1day).log\n
mv bbs_access.log bbs_access_$(date +%F -d -1day).log\n
mv index_access.log index_access_$(date +%F -d -1day).log\n
/application/nginx/sbin/nginx -s reload\n
##rsync to backup server\n
rsync -az \$DR --delete rsync_backup@\$IP::backup/ --password-file=/etc/rsync.passwd\n
#del date before 7 day ago\n
find \$DR -type f -name "*.log" -mtime +7 |xargs rm -f"|egrep -v "^$" >/server/scripts/cut_nginx_log.sh
chmod +x /server/scripts/cut_nginx_log.sh
#写入定时任务
echo "#nginx is log back cut\n00 00 * * * /bin/sh /server/scripts/cut_nginx_log.sh >/dev/null 2>&1" >>>>/var/spool/cron/root

#检查语法与重启
../sbin/nginx -t
../sbin/nginx -s reload
#######################################################################################################################################
################wordpress 博客搭建####################################################################################################
#######################################################################################################################################
cd /home/oldboy/tools/
tar xf wordpress-4.9.4-zh_CN.tar.gz
cp -a wordpress/* /application/nginx/html/blog/
chown -R www.www /application/nginx/html/blog/
/application/nginx/sbin/nginx -t
/application/nginx/sbin/nginx -s reload
w
###剩下就是调试工作
#1、数据库与nginx之间联通测试
#2、php测试页面编写以及测试访问
#3、博客搭建部分可省略

