#!/bin/bash

trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# https://stackoverflow.com/questions/4880290/how-do-i-create-a-crontab-through-a-script

# previous version
# (crontab -l 2>/dev/null; echo "*/5 * * * * /path/to/job -with args") | crontab -
# * * * * * if [ $(free -wm | awk ' /^Mem:/ { print $8 } ') -le 500 ]; then XDG_RUNTIME_DIR=/run/user/$(id -u) notify-send 'Short on memory, 500 Mb available left.'; fi

# changed priority to normal otherwise notifications vidget does not list critical type and they cannot be dismissed all at once
(crontab -l 2>/dev/null; echo '* * * * * if [ $(free -wm | awk '\''/^Mem:/ { print $8 }'\'') -le 500 ]; then XDG_RUNTIME_DIR=/run/user/$(id -u) notify-send -u normal '\''Available memory: 500 Mb only!'\''; fi') | crontab -
# firefox is now main app taking more and more memory as it runs
# after gecko install process name of firefox is GeckoMain 
(crontab -l 2>/dev/null; echo '* * * * * if [ $(free -wm | awk '\''/^Mem:/ { print $8 }'\'') -le 250 ]; then XDG_RUNTIME_DIR=/run/user/$(id -u) pkill firefox$ || pkill firefox-bin$ || pkill GeckoMain; fi') | crontab -

