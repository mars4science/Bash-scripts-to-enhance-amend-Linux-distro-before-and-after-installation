#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# code mentioned in lauchpad bug 1791427 (for X1 carbon gen 6 with NFC to fix non working after resume trackpoint), do not know how to check for PC model, seems now do not cause problems if run for others
# TODO test if fixes the issue if run on resume as programmed here (works if run manually after full wake up)

file_contents="#!/bin/sh

case $1 in
  pre) ;;
  post)
    echo -n "none" | sudo tee /sys/bus/serio/devices/serio1/drvctl
    echo -n "reconnect" | sudo tee /sys/bus/serio/devices/serio1/drvctl
    ;;
esac"

file_name=trackpoint_reset
file_fully_qualified_name=/lib/systemd/system-sleep/$file_name

if [ -e "$file_fully_qualified_name" ];then 
    1>&2 echo "$file_fully_qualified_name exists, next is programmed to abort configuring code to run on resume"
    exit 1
fi

# /dev/null not to output to terminal
echo "$file_contents" | 1>/dev/null sudo tee "$file_fully_qualified_name"
sudo chmod a+x "$file_fully_qualified_name"

