#!/bin/bash
# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; sleep 10; exit $err' ERR

# add applets/desklets software to Cinnamon
if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
sudo cp --recursive $software_path_root/cinnamon-applets/to_add/* /usr/share/cinnamon/applets
sudo cp --recursive $software_path_root/cinnamon-applets/to_add_and_activate/* /usr/share/cinnamon/applets
exit

# Notes:
1) to add applet to cinnamon one can download it from 
https://cinnamon-spices.linuxmint.com/applets/popular
and extract contents of archives to user folder
/home/mint/.local/share/cinnamon/applets
or system-wide one:
/usr/share/cinnamon/applets

2) if applet of the same name/(folder?), one in home overrides system-wide one

