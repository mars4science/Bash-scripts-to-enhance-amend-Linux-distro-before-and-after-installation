#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# to run those scripts after liveUSB boot that are user specific (set to run by systemd on boot WantedBy=multi-user.target)
# as casper scripts in initrd are not edited yet

full_path=`realpath $0` # man realpath : Print the resolved absolute file name;
dir_name=$(dirname $full_path)

$dir_name/add_ramdisk_and_ramcache.sh
$dir_name/after_login_config.sh
$dir_name/transmission_setup.sh
$dir_name/xscreensaver_setup.sh
$dir_name/dconf_config.sh
$dir_name/after_wine_run.sh

# change git config, e.g. colors of output for better visibility  
$dir_name/git_config.sh

# for our old printer (TODO fix printer to enable color output)
$dir_name/printer_color_as_gray.sh

# now color profile added only for T480s 
# TODO seems does not work by running by systemd on boot WantedBy=multi-user.target -> find out other way to run on boot
# $dir_name/set_color_profile.sh
