#!/bin/bash
# copy xscreensaver config file

# if current user is root (e.g. chrooted duriong liveUSB creation), then ~ would exist, but not /home/$(id -u -n)
if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
# for liveUSB boot 
if [ ! -e "${software_path_root}" ] ; then software_path_root=liveiso_path_settings_root ; fi

if [ -e /home/$(id -u -n) ]; then
    home_folder="/home/$(id -un)"
    cp --no-preserve=all "$software_path_root"/.xscreensaver "$home_folder"
    chmod o=r,ug=rw "$home_folder"/.xscreensaver
    sed --in-place --regexp-extended -- "s|^imageDirectory:	.*|imageDirectory:	${software_path_root}|" "$home_folder"/.xscreensaver # favourite backgrounds are assumed to be there (e.g. used for slideshow mode, which is close to zero CPU intensive as opposed to e.g. binaryring mode)
fi
