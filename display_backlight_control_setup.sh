#!/bin/bash
# thinkpad specific
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

sudo cp $(dirname "$(realpath "$0")")/bin/night $(get_install_path.sh)
sudo chmod +xs $(get_install_path.sh)/night

