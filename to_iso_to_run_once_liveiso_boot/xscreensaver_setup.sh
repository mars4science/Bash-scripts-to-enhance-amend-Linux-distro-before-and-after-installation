#!/bin/bash
# copy configs that set upload speed limit and seeding limits.

# if current user is root (e.g. chrooted duriong liveUSB creation), then ~ would exist, but not /home/$(id -u -n)
if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi
# for liveUSB boot 
if [ ! -e "${software_path_root}" ] ; then software_path_root=liveiso_path_settings_root ; fi

if [ -e /home/$(id -u -n) ]; then
    home_folder="/home/$(id -un)"
    cp --no-preserve=all "$software_path_root"/settings/xscreensaver/.xscreensaver "$home_folder"
    chmod o=r,ug=rw "$home_folder"/.xscreensaver
fi
