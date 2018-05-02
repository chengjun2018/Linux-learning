#!/bin/bash
#saltstack
#zuozhe CJ
#time 20180418
##Mastart端
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
yum install salt-master -y
chkconfig salt-master on 
###Minion端
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
yum install salt-minion -y
chkconfig salt-minion on

