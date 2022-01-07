#!/bin/bash

trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# https://stackoverflow.com/questions/4880290/how-do-i-create-a-crontab-through-a-script
# (crontab -l 2>/dev/null; echo "*/5 * * * * /path/to/job -with args") | crontab -
# * * * * * if [ $(free -wm | awk ' /^Mem:/ { print $8 } ') -le 500 ]; then XDG_RUNTIME_DIR=/run/user/$(id -u) notify-send 'Short on memory, 500 Mb available left.'; fi

# changed priority to normal otherwise notifications vidget does not list critical type and they cannot be dismissed all at once
(crontab -l 2>/dev/null; echo '* * * * * if [ $(free -wm | awk '\''/^Mem:/ { print $8 }'\'') -le 500 ]; then XDG_RUNTIME_DIR=/run/user/$(id -u) notify-send -u normal '\''Available memory: 500 Mb only!'\''; fi') | crontab -
# firefox is now main app taking more and more memory as it runs
# after gecko install process name of firefox is GeckoMain 
(crontab -l 2>/dev/null; echo '* * * * * if [ $(free -wm | awk '\''/^Mem:/ { print $8 }'\'') -le 250 ]; then XDG_RUNTIME_DIR=/run/user/$(id -u) pkill firefox$ || pkill GeckoMain; fi') | crontab -

# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command
