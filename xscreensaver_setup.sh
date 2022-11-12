#!/bin/bash
# copy configs that set upload speed limit and seeding limits.

# for liveUSB boot 
if [ ! -e "${software_path_root}" ] ; then software_path_root=/am ; fi

if [ -e /home/$(id -u -n) ]; then
    home_folder="/home/$(id -un)"
    cp --no-preserve=all "$software_path_root"/settings/xscreensaver/.xscreensaver "$home_folder"
    chmod o=r,ug=rw "$home_folder"/.xscreensaver
fi
