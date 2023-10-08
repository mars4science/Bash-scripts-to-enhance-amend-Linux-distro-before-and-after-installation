#!/bin/bash
trap 'err=$?; echo >&2 "Exiting $0 on error $err"; exit $err' ERR

# ` used instead of usual / in replace s as / is part of string to be replaced
sudo sed --in-place=bak 's`/^swap`#/swap`' /etc/fstab
sudo swapoff --all
# added to prevent error in case of liveUSB
if [ -e /swapfile ]; then sudo rm /swapfile; fi


