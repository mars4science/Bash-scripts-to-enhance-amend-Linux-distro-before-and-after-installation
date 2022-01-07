#!/bin/bash

# See [1] how to start firefox in separate instance with certain profile
# See [2] for way to get URLs and names of tabs in text format

# TODO add code to add restored tabs to new profile (interesting how to abnormally terminate not default profile - start firefox with it?)

# trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# where from to get data
backups_path=/media/$(id -un)/usb

# ====== #
source common_arguments_to_scripts.sh

# help
# -a does not shortcut against second part executing if first part is false;
# only strangely parathesis for test should be backslashed for proper syntax
# if [ ! $# -eq 0 -a \( $1 = "--help" -o $1 = "-h" \) ];then
if [ ! $# -eq 0 ] && [ $1 = "--help" -o $1 = "-h"  -o $1 = "?" ];then
    echo "Gets Firefox tabs from tar archive with "\""firefox-browser-sessionstore-backups"\"" in the name"
    echo "in "\""$backups_path"\"" and places in default profile"
    echo "in place of sessionstore-backups/recovery.jsonlz4, previous recovery.jsonlz4 replaces recovery.baklz4"
    echo "which is Firefox backup of recovery. To make Firefox use recovery, Firefox need to be [abnormally] terminated"
    echo "therefore if not running, it is first started, then terminated."
    echo "usage: $script_name"
    exit 0
fi
# ===== #

profiles_ini=/home/$(id -un)/.mozilla/firefox/profiles.ini
profile_path=$(cat $profiles_ini | grep Default | awk --field-separator "=" '{ FS = "=" ; print $2 ; exit }') 
full_profile_path=/home/$(id -un)/.mozilla/firefox/$profile_path

# -t     sort by modification time, newest first : man ls
# get latest backup / any original profile matches
tabs_path_backup=$(ls -t $backups_path | grep firefox-browser-sessionstore-backups | head --lines=1)

# end firefox process, $ at the end needed to skip firefox.real of TOR bundle
pkill firefox$ || pkill GeckoMain 

if [ $? -eq 1 ]; then # want to be sure firefox terminated abnormally
    echo "Firefox process not detected, if Firefox is running that means process name might be changed, script might need a fix," 
    read -p "not choosing to start Firefox has been coded to result in script run ending, start FF (y/n)? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1; fi
    &> /dev/null firefox & 
    # added "&> /dev/null" as firefox produces error messages, next line on start, after that on end with pkill GeckoMain
    # touch: cannot touch '/home/mint/.mozilla/93.0+linuxmint1+uma.dpkg_version': No such file or directory
    # Exiting due to channel error.
    i=1 # c style, bash can have inside "for" line and still use later
    for ((1; i <= 10; i++ )); do
        ps -e | grep "Web Content" > /dev/null # wait until windows/tabs are open just in case - 
                                               # noticed several times on next start displays an error about IIRC termination, advised to start in safe mode
        if [ $? -eq 0 ]; then 
            i=20; break;
        fi;
        sleep 1;
    done;
    if [ $i -eq 10 ]; then echo "Takes long to start firefox, maybe run the script later?"; exit; fi
    # end firefox process, $ at the end needed to skip firefox.real of TOR bundle
    pkill firefox$ || pkill GeckoMain
    if [ $? -eq 1 ]; then echo "cannot terminate firefox, exiting..."; exit 1; fi
fi

cd $full_profile_path
mv --force sessionstore-backups/recovery.jsonlz4 sessionstore-backups/recovery.baklz4
tar --extract --file=$backups_path/$tabs_path_backup ./sessionstore-backups/recovery.jsonlz4 # --overwrite just in case, left from other script

exit

# not needed, done by bash by default
# cd $path_original

[1]
# does & at the end needed?
firefox -no-remote -P name_of_profile 

[2]
the following produces list of tab names with URLs from sessionstore-backups/recovery.jsonlz4

lz4jsoncat ~/.mozilla/firefox/*default*/sessionstore-backups/recovery.jsonlz4 \
  | jq '.["windows"] | .[0] | .["tabs"] | .[] | .["entries"] | .[0] | .url,.title' \
  | grep -v 'New Tab' | grep -v 'about:newtab' | sed 's/"http/\n"http/g'
