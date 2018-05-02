#!/bin/bash
##locahost YUM Repository
##zuozhe cj
##time 20180411
YUM="/application/yum/centos6.6/x86_64/"
mkdir -p $YUM
cd $YUM
##将已经下载好的rpm包放进$YUM目录下
##
yum -y install createrepo
createrepo -pdo /application/yum/centos6.6/x86_64/ /application/yum/centos6.6/x86_64/
##
cd $YUM
python -m SimpleHTTPServer 80 &>/dev/null &
####################################################
yumdownloader pcre-devel openssl-devel
#####################################
createrepo --update /application/yum/centos6.6/x86_64/ 
#############
#完成后，可在浏览器输入IP查看是否有程序列表

