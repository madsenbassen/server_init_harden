#!/bin/bash
#
#
# Used to upload private/pub keys to NFS drive, to access it from us the user. 
# Might propose a security risk
#
#
#
#
#
# This script should do:
#
# 1) test if nfs folder is mounted and exit 0 if yes
# 2) try to mount it and exit 0 if success
# 3) try to wake the server if not possible to mount
# 4) wait while its not woked (pinging)
# 5) try againt 2-4 several times
#

# settings
target_ip=192.168.1.10
target_folder=/home/share
target_mac=11:22:33:44:55:66
mount_folder=/mnt/nfs/server
mount_attempts=3
ping_attempts=5

#test if its already mounted
if [ -n "`mount | grep $mount_folder`" ]; then
  echo "Server already mounted."
  exit 0
fi

if [ ! -d "$mount_folder" ]; then
  echo "Mount point $mount_folder doesn't exist"
  exit 1
fi

#loop (set number of attempts here)
for ((mount_cnt=1; mount_cnt<=$mount_attempts; mount_cnt++))
do
  echo -n "Attempt to mount ($mount_cnt/3): "
  #mount attempt (set server ip and shared folder)
  mount $target_ip:$target_folder $mount_folder

  #test if it worked
  if [ $? -eq 0 ]; then
    echo "Server succesfully mounted."
    exit 0
  else
    #test if wakeonlan installed
    command -v wakeonlan >/dev/null 2>&1 || { echo "Error: wakeonlan not installed .. Aborting." >&2; exit 1; }
    #try to wake server (set server mac)
    wakeonlan $target_mac
    #ping until not ready
    echo -n "Ping attempts ."
    for ((ping_cnt=1; ping_cnt<=$ping_attempts; ping_cnt++))
    do
      ping -c 1 $target_ip > /dev/null
      if [ $? -eq 0 ]; then
        echo -n " success."
        break
      else
        echo -n "."
      fi
    done
    echo
  fi
done

echo "Error: Unable to mount server."
exit 1
