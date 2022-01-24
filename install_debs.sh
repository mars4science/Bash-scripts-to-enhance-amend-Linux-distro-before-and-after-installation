#!/bin/bash
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# install all packages from local storage using apt_get.sh 
# as apt_get got altered to output all errors at the end, developer changes this script to run apt_get only once, not for every package.
# In fact the developed does not recall why longer code [1] was developed in the first place

ls -1 "$(./apt_get.sh printpath)" | ./apt_get.sh -i
exit

===== previous version follows =====

[1] 
# -L to follow links, one may create a directory with links for specific install, edit default_local_debs line in apt_get.sh
find -L "$(./apt_get.sh printpath)" -maxdepth 1 -mindepth 1 -type d -execdir bash -c 'basename $(ls -d1 "{}")' \; | { while read debs_path; do echo $debs_path | ./apt_get.sh -i; done; }

# ln -s /media/mint/usb/LM_20.2/stress_1 /media/mint/usb/LM_20.tmp
# ln -s /media/mint/usb/LM_20.2/stress-ng_1 /media/mint/usb/LM_20.tmp
# echo stress_1 | apt_get -i # works on liveUSB

