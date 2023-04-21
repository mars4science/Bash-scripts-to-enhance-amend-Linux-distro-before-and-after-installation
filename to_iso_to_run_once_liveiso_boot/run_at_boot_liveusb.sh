#!/bin/bash

user_name=mint
# change liveUSB user id to usual id after install to easier access to files (to make appear as same ownership)
usermod --uid 1000 $user_name
groupmod --gid 1000 $user_name

full_path=`realpath $0` # man realpath : Print the resolved absolute file name;
dir_name=$(dirname $full_path)
$dir_name/libvirt_access_rights.sh "$user_name"

# change default /tmp size if already present in fstab, otherwise add; moved here as /etc/fstab is overshowed during liveISO boot
if [[ ! $(grep '/tmp' /etc/fstab) ]]; then
    echo 'tmpfs /tmp tmpfs size=10%,noatime,nosuid,nodev 0 0' | sudo tee --append /etc/fstab
else
    sudo sed --in-place --regexp-extended -- 's|tmpfs /tmp tmpfs nosuid,nodev|tmpfs /tmp tmpfs size=10%,noatime,nosuid,nodev|' /etc/fstab
fi

echo custom init finish, next call /sbin/init
sleep 5
exec /sbin/init

