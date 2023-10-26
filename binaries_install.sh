#!/bin/bash

# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi

sudo cp --no-clobber "$software_path_root"/bin/the_rest/* "$(get_install_path.sh)" # expected to have exec bit set in "$software_path_root", not setting here

# copy apps in form of AppImage to disk and menu (to list of All Applications)
sudo cp --no-clobber "$software_path_root"/bin/appimages/* "$(get_install_path.sh)"
sudo cp --no-clobber "$software_path_root"/bin/desktops/* /usr/share/applications
sudo cp --no-clobber "$software_path_root"/bin/icons/* /usr/share/pixmaps

sudo ln --relative --symbolic "$(get_install_path.sh)"/kiwix*.appimage "$(get_install_path.sh)"/kiwix.appimage # for desktop file to be independent of kiwix version

