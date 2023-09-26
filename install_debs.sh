#!/bin/bash
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# install all packages from local storage using apt_get.sh 
# as apt_get got altered to output all errors at the end, developer changes this script to run apt_get only once, not for every package.
# In fact the developed does not recall why longer code [1] was developed in the first place

# changed to sort by modification date of folders, newest last; that way latest downloaded are installed last
ls -1tr "$(./apt_get.sh printpath)" | ./apt_get.sh -i # (list files by modification time reversed)
# TODO: understand why there are errors during installation if list of folders with debs is ordered alphabetically (want to switch because consider it more convenient to ensure desired ordering). Part of the cause (hypothesis): Errors are due to diffeent ordering from order in which packages were added.
exit

===== previous version follows =====

[1] 
# -L to follow links, one may create a directory with links for specific install, edit default_local_debs line in apt_get.sh
#find -L "$(./apt_get.sh printpath)" -maxdepth 1 -mindepth 1 -type d -execdir bash -c 'basename $(ls -d1 "{}")' \; | { while read debs_path; do echo $debs_path | ./apt_get.sh -i; done; }
# changed to sort by modification date of folders, newest last; that way latest downloaded are installed last
#find -L "$(./apt_get.sh printpath)" -maxdepth 1 -mindepth 1 -type d -printf "%T@ %Tc %p\n" | sort -n | awk '{print $7}' | xargs -L 1 basename | ./apt_get.sh -i

# ln -s /media/mint/usb/LM_20.2/stress_1 /media/mint/usb/LM_20.tmp
# ln -s /media/mint/usb/LM_20.2/stress-ng_1 /media/mint/usb/LM_20.tmp
# echo stress_1 | apt_get -i # works on liveUSB
