#!/bin/bash
##Nginx and load balancing a key to install the debug script.
#editor CJ
#Time 20180418
#qq 278028843
##########################################################################################################################
################负载均衡 搭建lb02#########################################################################################
##########################################################################################################################
hostname lb02
/bin/sed -i 's#HOSTNAME=backup#HOSTNAME=lb02#' /etc/sysconfig/network
######################################################################################
/bin/sed  -i 's#IPADDR=10.0.0.100#IPADDR=10.0.0.6#' /etc/sysconfig/network-scripts/ifcfg-eth0
/bin/sed -i 's#IPADDR=172.16.1.100#IPADDR=172.16.1.6#' /etc/sysconfig/network-scripts/ifcfg-eth1
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
#########################################################
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
################################################################
yum install openssl openssl-devel pcre pcre-devel -y
useradd www -s /sbin/nologin -M
mkdir -p /home/oldboy/tools/
mkdir -p /application/
cd /home/oldboy/tools/
wget -q http://nginx.org/download/nginx-1.6.3.tar.gz
tar xf nginx-1.6.3.tar.gz
cd nginx-1.6.3
./configure --user=www --group=www --prefix=/application/nginx1.6.3 --with-http_stub_status_module --with-http_ssl_module
make
make install
ln -s /application/nginx1.6.3/ /application/nginx
/application/nginx/sbin/nginx
负载均衡配置#/application/nginx/conf/nginx.conf
echo -e "worker_processes  1;\n
events {\n
    worker_connections  1024;\n
}\n
http {\n
    include       mime.types;\n
    default_type  application/octet-stream;\n
    sendfile        on;\n
    keepalive_timeout  65;\n

upstream server_pools {\n
      server 10.0.0.7:80 weight=1;\n
      server 10.0.0.8:80 weight=1;\n
   }\n
    server {\n
        listen       80;\n
        server_name  blog.51cto.com;\n
        location / {\n
            proxy_pass http://server_pools;\n
            proxy_set_header  Host \$host;\n
            proxy_set_header X-Forwarded-For \$remote_addr;\n 

        }\n
        }\n
    server {\n
        listen       80;\n
        server_name  www.51cto.com;\n
        location / {\n
            proxy_pass http://server_pools;\n
            proxy_set_header  Host \$host;\n
            proxy_set_header X-Forwarded-For \$remote_addr;\n 
        }\n
        }\n
    server {\n
        listen       80;\n
        server_name  bbs.51cto.com;\n
        location / {\n
            proxy_pass http://server_pools;\n
            proxy_set_header  Host \$host;\n
            proxy_set_header X-Forwarded-For \$remote_addr;\n
        }\n
        }\n
}"|egrep -v "^$" >/application/nginx/conf/nginx.conf
#重启nginx-lb01
/application/nginx/sbin/nginx -s reload
###########################################
#keepalived搭建及配置lb02##################
###########################################
cd /home/oldboy/tools/
yum install keepalived -y
/bin/echo -e "! Configuration File for keepalived\n
\n
global_defs {\n
   notification_email {\n
     acassen@firewall.loc\n
     failover@firewall.loc\n
     sysadmin@firewall.loc\n
   }\n
   notification_email_from Alexandre.Cassen@firewall.loc\n
   smtp_server 192.168.200.1\n
   smtp_connect_timeout 30\n
   router_id LVS_DEVEL1\n
}\n
\n
vrrp_instance VI_1 {\n
    state BACKUP\n
    interface eth0\n
    virtual_router_id 51\n
    priority 100\n
    advert_int 1\n
    authentication {\n
        auth_type PASS\n
        auth_pass 1111\n
    }\n
    virtual_ipaddress {\n
        10.0.0.3/24 dev eth0 label eth0:1\n
    }\n
}"|egrep -v "^$" >/etc/keepalived/keepalived.conf
/etc/init.d/keepalived restart
/bin/echo "/etc/init.d/keepalived start" >>/etc/rc.local
/etc/init.d/network reload
who
