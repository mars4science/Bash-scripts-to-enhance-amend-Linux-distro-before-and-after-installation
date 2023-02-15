#!/bin/bash
# copy sql code colors for sqlite browser

# if current user is root (e.g. chrooted duriong liveUSB creation), then ~ would exist, but not /home/$(id -u -n)
if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
# for liveUSB boot
if [ ! -e "${software_path_root}" ] ; then software_path_root=liveiso_path_settings_root ; fi

if [ -e /home/$(id -u -n) ]; then
    home_folder="/home/$(id -un)/.config/sqlitebrowser"
    if [ ! -d "$home_folder" ]; then mkdir --parents "$home_folder"; fi 
    cp --no-preserve=all "$software_path_root"/sqlitebrowser/* "$home_folder"
    chmod a=r,u=rw "$home_folder"/*
fi
