#!/bin/bash
# copy configs that set upload speed limit and seeding limits.

# if current user is root (e.g. chrooted duriong liveUSB creation), then ~ would exist, but not /home/$(id -u -n)
if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi
# for liveUSB boot 
if [ ! -e "${software_path_root}" ] ; then software_path_root=/am ; fi

if [ -e /home/$(id -u -n) ]; then
    # the json files originally had acces rights -rw-------, but copy via different users' accounts ids have to add access to others,
    # so (not tested yet) copy without attributes and set file mode bits later
    # script_path_folder=$(dirname $(realpath $0))
    transmission_home_folder="/home/$(id -un)/.config/transmission"
    if [ ! -d "$transmission_home_folder" ]; then mkdir --parents "$transmission_home_folder"; fi 
    cp --no-preserve=all "$software_path_root"/transmission-settings/*.json "$transmission_home_folder"
    sed --in-place 's`/mint/`/'$(id -un)'/`' $transmission_home_folder"/settings.json
    chmod a=,u=rw $transmission_home_folder"/*
fi
