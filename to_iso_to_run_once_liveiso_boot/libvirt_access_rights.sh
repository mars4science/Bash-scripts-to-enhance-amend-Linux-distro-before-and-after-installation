#!/bin/bash

# script to be invoked from run_at_boot_liveusb.sh with parameter, after_original_distro_install.sh w/out
if [ $# -eq 0 ]; then user_name=$(id -un); else user_name=$1; fi

# to fix Virtual Machine Manager error to add QEMU/KVM connection
sudo usermod --append --groups libvirt $user_name

# to fix error when Virtual Machine Manager creates new VM, often ISOs (and other info) are stored on mounted to drives in /media/user_name
# below folder is created when user mounts some volume in GUI (at that time system gives user rx permissions for it)
# therefore need to do that in advance to add libvirt to ACL in advance
sudo mkdir --parents /media/$user_name
sudo chmod o-rwx /media/$user_name # remove access to others if given, next add specific users
sudo setfacl -m u:$user_name:rx /media/$user_name
sudo setfacl -m u:libvirt-qemu:x /media/$user_name



