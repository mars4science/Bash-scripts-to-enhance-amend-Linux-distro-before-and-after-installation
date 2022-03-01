#!/bin/bash
# thinkpad specific
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi

sudo cp "$software_path_root"/files.py $(get_install_path.sh)
sudo cp "$software_path_root"/files_functions.py $(get_install_path.sh)
sudo chmod +xs $(get_install_path.sh)/files.py

