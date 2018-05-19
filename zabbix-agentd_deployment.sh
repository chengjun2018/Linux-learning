#!bin/bash
#zabbix-agentd clinet deployment
#time 2018-05-19
#cj
groupadd zabbix 
useradd -g zabbix -m zabbix
cd /home/oldboy/tools/
wget http://jaist.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.0.4/zabbix-3.0.4.tar.gz
tar xf zabbix-3.0.4.tar.gz 
cd zabbix-3.0.4
./configure --prefix=/etc/zabbix --enable-agent
make install
cd /home/oldboy/tools/
cp zabbix-3.0.4/misc/init.d/tru64/zabbix_agentd /etc/init.d/
chmod +x /etc/init.d/zabbix_agentd
sed -i 's#127.0.0.1#172.16.1.71#g' /etc/zabbix/etc/zabbix_agentd.conf
sed -i 's#Zabbix server#db02#g' /etc/zabbix/etc/zabbix_agentd.conf
egrep -v "^#|^$" /etc/zabbix/etc/zabbix_agentd.conf >CONG.CNF
ln -s /etc/zabbix/sbin/* /usr/local/sbin/
ln -s /etc/zabbix/bin/* /usr/local/bin/
