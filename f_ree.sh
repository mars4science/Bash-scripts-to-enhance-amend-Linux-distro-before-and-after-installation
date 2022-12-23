#!/bin/bash

# to delete usually unneeded files in memory gets low on booted to RAM system

# ====== #
source common_arguments_to_scripts.sh
# help
help_message="  For current user: deletes caches, empties Trash, deletes wine user files/data in user wine prefix folder.
  Usage: $script_name\n"
display_help "$help_message$common_help"
# ===== #

remove_if_exists() {
    if [ -d $1 ]; then rm --force --recursive $1/*; fi
}

remove_if_exists ~/.cache
remove_if_exists ~/.wine
remove_if_exists ~/.local/share/wineprefixes
remove_if_exists ~/.local/share/Trash
remove_if_exists ~/.local/share/baloo # not sure that index service is useful taking into account it takes CPU resources

ff_profiles="/home/$(id -un)/.mozilla/firefox/profiles.ini"
if [ -e "$ff_profiles" ]; then
    firefox_profile_path=$(cat /home/$(id -un)/.mozilla/firefox/profiles.ini | grep ^Default | grep --invert-match "Default=1" | head --lines=1 | awk --field-separator "=" '{ FS = "=" ; print $2 ; exit }')
    remove_if_exists ~/.mozilla/firefox/$firefox_profile_path/storage
fi
sudo rm --force --recursive /var/log/*

# end Windows (wine) processes after deleting Windows disks (~./wine)
# often there are none, so 2>/dev/null to prevent an error displayed
ps -e -f | grep '\.exe' | grep ' [C|Z]:\\' | awk '{print $2}' | 2>/dev/null xargs kill

exit

# ============= comments below ================== #
several positional parameters can be supplied to the function
search in man bash:
"A shell function" 
