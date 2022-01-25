#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# to run those scripts after liveUSB boot that are user specific
# as casper scripts in initrd are not edited yet

full_path=`realpath $0` # man realpath : Print the resolved absolute file name;
dir_name=$(dirname $full_path)

$dir_name/add_ramdisk_and_ramcache.sh
$dir_name/after_login_config.sh
$dir_name/transmission_setup.sh
$dir_name/dconf_config.sh
$dir_name/after_wine_run.sh
