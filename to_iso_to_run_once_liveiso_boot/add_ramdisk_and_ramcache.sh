#!/bin/bash
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# add ramdisk for work and make link to it from use home
# make cache reside in RAM

# ! for zram, after some files deleted there, looks like needed to run manually `sudo fstrim /mountpoint` to discard memory (unused blocks)

# new way for ramdisk
grep 'tmpfs /media/ramdisk' /etc/fstab
if [ $? -ne 0 ]; then
    echo 'tmpfs /media/ramdisk tmpfs size=100%,x-mount.mkdir,noatime 0 0' | sudo tee --append /etc/fstab
fi

# adding zramdisk via mount helper resulted in disk visible after boot, but not opening, so comment out /dev/zram0
# echo '/dev/zram0 /media/zramdisk zramdisk x-systemd.automount,x-mount.mkdir,discard,noatime,dev,suid,exec 0 0' | sudo tee --append /etc/fstab
grep 'tmpfs /home/root/.cache' /etc/fstab
if [ $? -ne 0 ]; then
    echo 'tmpfs /home/root/.cache tmpfs size=1%,noatime 0 0' | sudo tee --append /etc/fstab
fi

# swap in zram in case will be needed.
# as zram device is not available on early during boot, fstab entry does not result in automatic swap activation
# with this entry in fstab swap can be started either `swapon /dev/zram1` or `swapon --all`
grep '/dev/zram1' /etc/fstab
if [ $? -ne 0 ]; then
    echo '/dev/zram1 none swap 0 0' | sudo tee --append /etc/fstab
fi

# the below moved to /boot/init_custom.sh (made via run_at_boot_config.sh) as home is encrypted and links need to be added at boot,
# might be ok to add via systemd,
# but I decided to add script to run after kernel start before systemd (systemd processed /etc/fstab - see /var/log).
# echo 'tmpfs /var tmpfs size=5% 0 0' | sudo tee --append /etc/fstab

# if home is encrypted, that entry is fstab would be overwritten when 
# encryptfs is initialized: systemd: "Reached target Local Encrypted Volumes"
# therefore using noauto in /etc//fstab and mounting in user .profile file.
grep "tmpfs /home/$(id -u -n)/.cache" /etc/fstab
if [ $? -ne 0 ]; then
    echo 'tmpfs /home/'$(id -u -n)'/.cache tmpfs size=5%,noauto,user,noatime 0 0' | sudo tee --append /etc/fstab
fi

# add noatime, then access time not changed on access, saving SSD, even if timestamp of access is older then 1 day (man mount
# "In addition, since Linux 2.6.30, the file's last access time is always updated if it is more than 1 day old."- than it is inddeed for relatime only
sudo sed --in-place --regexp-extended -- 's/errors=remount-ro/errors=remount-ro,noatime/' /etc/fstab

# ram disk was? needed for some install scripts later
# also developer found out that during liveUSB boot /etc/fstab file in squashfs gets overshadowed,
# so next line is "user specfic" (to be run after boot)
sudo mount /media/ramdisk
# sudo mount /media/zramdisk, now mounted in add_zram.sh

