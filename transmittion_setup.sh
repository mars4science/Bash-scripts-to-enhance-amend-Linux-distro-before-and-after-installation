#!/bin/bash
# copy configs that set upload speed limit and seeding limits.

# if current user is root (e.g. chrooted duriong liveUSB creation), then ~ would exist, but not /home/$(id -u -n)
if [ -e /home/$(id -u -n) ]; then
    # the json files originally had acces rights -rw-------, but copy via different users' accounts ids have to add access to others,
    # so (not tested yet) copy without attributes and set file mode bits later
    script_path_folder=$(dirname $(realpath $0))
    transmission_home_folder="/home/$(id -un)/.config/transmission"
    if [ ! -d "$transmission_home_folder" ]; then mkdir --parents "$transmission_home_folder"; fi 
    cp --no-preserve=all "$script_path_folder"/settings/transmission/*.json "$transmission_home_folder"
    sed --in-place 's`/mint/`/'$(id -un)'/`' /home/$(id -un)/.config/transmission/settings.json
    chmod a=,u=rw /home/$(id -un)/.config/transmission/*
fi
