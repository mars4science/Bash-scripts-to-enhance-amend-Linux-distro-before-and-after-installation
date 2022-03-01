#!/bin/bash

# replaces in Linux Mint modified (at least for google search) Mozilla Firefox with downloaded from Mozilla site version

ff_installed_link=$(which firefox)
# man bash:
#       -h file
#              True if file exists and is a symbolic link.
if [ -h "$ff_installed_link" ]; then ff_link_symbolic=true; else ff_link_symbolic=false; fi
# 1 argument
#                     The expression is true if and only if the argument is not null.
# therefore when $ff_installed_link is empty, then only one argument: -h so exprsssion AFAIK evaluates to true
# added "" (below too), so now expression has two arguments: -h and a string

ff_installed_folder=$(dirname $(realpath $ff_installed_link))
if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi
ff_archive_name=$(ls --sort=time $software_path_root | grep firefox- | head --lines=1)
ff_archive=$software_path_root/$ff_archive_name

if [ ! -d "$ff_installed_folder" ]; then echo >&2 "Firefox not found on the system, next is exit of the script"; exit 1; fi
if [ ! -f "$ff_archive" ]; then echo >&2 "Firefox archive to install from not found in $software_path_root, next is exit of the script"; exit 1; fi

cd $ff_installed_folder
sudo rm --recursive ./* 
sudo tar --extract --file=$ff_archive 

# restore link that the srcipt code as written is supposed to break
if [ "$ff_link_symbolic" = "true" ]; then sudo ln --symbolic --force $ff_installed_folder/firefox $ff_installed_link; fi

# disable updates (inc. reminders)
sudo mkdir $ff_installed_folder/distribution
echo '{"policies": {"DisableAppUpdate": true}}' | 1>/dev/null sudo tee $ff_installed_folder/distribution/policies.json



