#\!/bin/bash
##md5sum flag Key and mail to 278028843
#zuozhe
#time-20180329
IP=$(ifconfig eth1|awk -F "[ :]+" 'NR==2{print $4}')
Path="/backup/"
if [ $(date +%w) -eq 0 ]
then
   Time=week_$(date +%F_%w -d -1day)
else
   Time=$(date +%F -d -1day)
fi
LANG=en
find $Path  -type f -name "*${Time}*.log"|xargs md5sum -c >>$Path/mail_cj_${Time}.log 2>&1
#mail to administrator
mail -s "$Time  back" 278028843@qq.com <$Path/mail_cj_${Time}.log
##del 180 day and by saturday data  
/bin/find /backup/ -type f -mtime +180  ! -name "*week*_6*"|xargs rm -f
