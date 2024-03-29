#!/bin/bash
trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# where to put data
backups_path=/media/$(id -un)/usb
ff_path=/home/$(id -un)/.mozilla/firefox

# ====== #
source "$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
# help
help_message="  Puts tabs backup of default Firefox profile in tar format to: $backups_path.
  if path is given as argument, tabs files are backed up to that location.
  Usage: $script_name [path]\n"
display_help "$help_message$common_help" 
# ====== #

# used with . and w/out realpath it put archive in a profile folder
if [ $# -eq 1 ];then backups_path="$(realpath $1)"; fi

profile_path=$(cat $ff_path/profiles.ini | grep ^Default | grep --invert-match "Default=1" | head --lines=1 | awk --field-separator "=" '{ FS = "=" ; print $2 ; exit }') 

cd $ff_path/$profile_path

# sessionstore-backups needed for tabs transfer
tar --create --verbose --verify --file=$backups_path/firefox-browser-sessionstore-backups-$profile_path-`date +'.%Y-%m-%d_%H-%M-%S.tar'` \
./sessionstore-backups

exit

# not needed, done by bash by default
# cd $path_original

# does & at the end needed?
firefox -no-remote -P name_of_profile 

