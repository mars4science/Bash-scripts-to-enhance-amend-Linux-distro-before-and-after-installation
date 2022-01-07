#!/bin/bash
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# add ramdisk for work and make link to it from use home
# make cache reside in RAM

# new way for ramdrive
echo 'tmpfs /media/ramdrive tmpfs size=100%,noatime,x-mount.mkdir,noatime 0 0' | sudo tee --append /etc/fstab
echo 'tmpfs /home/root/.cache tmpfs size=1%,noatime 0 0' | sudo tee --append /etc/fstab

# the below moved to /boot/init_custom.sh as home is encrypted and links need to be added at boot, might be ok to add via systemd,
# but I decided to add script to run after kernet start before systemd (systemd processed /etc/fstab - see /var/log)
# echo 'tmpfs /var tmpfs size=5% 0 0' | sudo tee --append /etc/fstab
# echo 'tmpfs /tmp tmpfs size=5% 0 0' | sudo tee --append /etc/fstab

# if home is encrypted, that entry is fstab would be overwritten when 
# encryptfs is initialized: systemd: "Reached target Local Encrypted Volumes"
# therefore using noauto in /etc//fstab and mounting in user .profile file.
echo 'tmpfs /home/'$(id -u -n)'/.cache tmpfs size=5%,noauto,user,noatime 0 0' | sudo tee --append /etc/fstab

# add noatime, then access time not changed on access, saving SSD, even if timestamp of access is older then 1 day (man mount
# "In addition, since Linux 2.6.30, the file's last access time is always updated if it is more than 1 day old."- than it is inddeed for relatime only
sudo sed --in-place --regexp-extended -- 's/errors=remount-ro/errors=remount-ro,noatime/' /etc/fstab

# ram drive is needed for some install scripts later
sudo mount tmpfs /media/ramdrive -t tmpfs -o size=100%,rw,noatime,x-mount.mkdir

