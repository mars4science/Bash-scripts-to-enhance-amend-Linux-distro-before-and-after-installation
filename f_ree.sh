#!/bin/bash

# to delete usually unneeded files in memory gets low on booted to RAM system

# ====== #
source "$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
# help
help_message="  For current user: deletes caches, empties Trash, deletes wine user files/data in user wine prefix folder.
  Usage: $script_name\n"
display_help "$help_message$common_help"
# ===== #

remove_if_exists() {
    if [ -d $1 ]; then rm --force --recursive $1/* $1/.[!.]*; fi # added for files starting with ., not selected by *; [!.] means all characters except ., to filter out . and ..
}

remove_if_exists ~/.cache
remove_if_exists ~/.wine

# remove_if_exists ~/.local/share/wineprefixes
# remove_if_exists ~/.local/share/Trash
# remove_if_exists ~/.local/share/baloo # not sure that index service is useful taking into account it takes CPU resources
remove_if_exists ~/.local/share

ff_profiles="/home/$(id -un)/.mozilla/firefox/profiles.ini"
if [ -e "$ff_profiles" ]; then
    firefox_profile_path=$(cat /home/$(id -un)/.mozilla/firefox/profiles.ini | grep ^Default | grep --invert-match "Default=1" | head --lines=1 | awk --field-separator "=" '{ FS = "=" ; print $2 ; exit }')
    remove_if_exists ~/.mozilla/firefox/$firefox_profile_path/storage
fi

sudo rm --force --recursive /var/log/*
# /tmp/.X11-unix/X0 is a socket file, e.g. com.github.johnfactotum.Foliate version 2.6.4 seems to be needed it to work properly, renaming preserves it
sudo mv /tmp/.X11-unix /tmp/..X11-unix
sudo rm --force --recursive /tmp/* /tmp/.[!.]*
sudo mv /tmp/..X11-unix /tmp/.X11-unix

sudo apt-get clean # just in case too

# end Windows (wine) processes after deleting Windows disks (~./wine)
# often there are none, so 2>/dev/null to prevent an error displayed
ps -e -f | grep '\.exe$' | grep ' [C|Z]:\\' | awk '{print $2}' | 2>/dev/null xargs kill

exit

# ============= comments below ================== #
several positional parameters can be supplied to the function
search in man bash:
"A shell function" 
