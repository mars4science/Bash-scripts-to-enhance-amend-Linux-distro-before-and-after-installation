#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# add applets/desklets software to Cinnamon
if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi
sudo cp --recursive $software_path_root/cinnamon-applets/* /usr/share/cinnamon/applets

exit

to add applet to cinnamon one can download it from 
https://cinnamon-spices.linuxmint.com/applets/popular
and extract contents of archives to user folder
/home/mint/.local/share/cinnamon/applets
or system-wide one:
/usr/share/cinnamon/applets

# TODO
There is an outstanding issue of settings, not fully done yet, started work in cinnamon_config_software.sh
Configs/settings are in the form of folders with json files in:
/home/mint/.cinnamon/configs
 
