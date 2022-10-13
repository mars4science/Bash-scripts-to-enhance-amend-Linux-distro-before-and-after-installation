#!/bin/bash
# thinkpad specific
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi

sudo cp --no-clobber "$software_path_root"/bin/the_rest/* "$(get_install_path.sh)"
# expected to have exec bit set in "$software_path_root", not setting here

# app apps in form of AppImage to disk and menu (to list of All Applications)
sudo cp --no-clobber "$software_path_root"/bin/appimages/* "$(get_install_path.sh)"
sudo cp --no-clobber "$software_path_root"/bin/desktops/* /usr/share/applications
sudo cp --no-clobber "$software_path_root"/bin/icons/* /usr/share/pixmaps


