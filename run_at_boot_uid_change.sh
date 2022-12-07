#!/bin/bash

user_name=mint
usermod --uid 1000 $user_name
groupmod --gid 1000 $user_name

# to fix Virtual Machine Manager error to add QEMU/KVM connection
usermod --append --groups libvirt $user_name

# to fix error when Virtual Machine Manager creates new VM, often ISOs (and other info) are stored on mounted to drives in /media/user_name
# below folder is created when user mounts some volume in GUI (at that time system gives user rx permissions for it)
# therefore need to do that in advance to add libvirt to ACL in advance
sudo mkdir /media/$user_name
sudo chmod o-rwx /media/$user_name # remove access to others if given, next add specific users
sudo setfacl -m u:$user_name:rx /media/$user_name
sudo setfacl -m u:libvirt-qemu:x /media/$user_name

echo custom init finish, next call /sbin/init
sleep 5
exec /sbin/init

