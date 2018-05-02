#\!/bin/bash
#The is inotify and rsync dir by shell
#zuozhe cj
#time 20180401
IP=172.16.1.41
Path=/nfsbackup/
/usr/bin/inotifywait -mrq  --format '%w%f' -e close_write,delete $Path \
|while read file
do
   cd $Path
if [ -f $file ];then
   rsync -az $file --delete rsync_backup@$IP::nfsbackup/ --password-file=/etc/rsync.password
else
   cd $Path &&
   rsync -az ./ --delete rsync_backup@$IP::nfsbackup/ --password-file=/etc/rsync.password
   fi
  done
