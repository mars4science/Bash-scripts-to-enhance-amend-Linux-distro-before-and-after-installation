#!/bin/bash
# thinkpad specific
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

software_path_root=/media/$(id -un)/usb/LM_20.2
sudo cp "$software_path_root"/bin/night $(get_install_path.sh)
sudo chmod +xs $(get_install_path.sh)/night

