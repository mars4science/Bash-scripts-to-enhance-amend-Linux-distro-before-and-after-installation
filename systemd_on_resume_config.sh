#!/bin/bash
# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; sleep 10; exit $err' ERR

# code mentioned in lauchpad bug 1791427 (for X1 carbon gen 6 with NFC to fix non working after resume trackpoint), do not know how to check for PC model, seems now do not cause problems if run for others
# TODO test if fixes the issue if run on resume as programmed here (works if run manually after full wake up)
# result of test: not working. TODO find other ways to fix automatically, for now added custom keys to activate fix code in dconf_config.sh

if [ ! -e "${liveiso_path_scripts_root}" ] ; then liveiso_path_scripts_root=/usr/bin/am-scripts ; fi

folder_for_code_to_run_on_suspend="/lib/systemd/system-sleep/"

add_file_to_systemd_system-sleep () {

    file_fully_qualified_name="${folder_for_code_to_run_on_suspend}/${file_name}"
    if [ -e "$file_fully_qualified_name" ];then 
        1>&2 echo -e "\n  WARNING: $file_fully_qualified_name exists, next is programmed NOT to add\n$file_contents\n  to code potentially to be run via systemd suspend/resume\n"
    else
        # /dev/null not to output to terminal
        echo "$file_contents" | 1>/dev/null sudo tee "$file_fully_qualified_name"
        sudo chmod a+x "$file_fully_qualified_name"
    fi
}


# reset trackpoint if stops working after suspend (happens on some ThinkPads)
# decided to use keyboard binding later - key) not post) - as only some models need that
file_contents='#!/bin/sh

case $1 in
  pre) ;;
  post) ;;
  key)
    echo -n "none" | sudo tee /sys/bus/serio/devices/serio1/drvctl
    sleep 3    
    echo -n "reconnect" | sudo tee /sys/bus/serio/devices/serio1/drvctl
    ;;
esac'

file_name=trackpoint_reset
add_file_to_systemd_system-sleep


# set screen scaling as dconf scaling-factor value seems to be reset on resume
# Note: on Linux Mint 21 the command (gsettings set org.cinnamon.desktop.interface scaling-factor 2) seems does not work
file_name=scaling_factor
file_fully_qualified_name="${folder_for_code_to_run_on_suspend}/${file_name}"

if [ -e "$file_fully_qualified_name" ];then
    1>&2 echo "  WARNING: $file_fully_qualified_name exists, next is programmed not to configure code to run on resume for dconf scaling-factor issue fix (as probably configured already)"
else
    # /dev/null not to output to terminal
    # EOF is quoted to prevend expansion/substitution
    sudo tee "$file_fully_qualified_name" >/dev/null <<-"EOF"
#!/bin/sh

case $1 in
  pre) ;;
  post) ;;
  key)

dpm=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4/$(NF-1)}') # dots per millimeter, rounded as bash test works with integers only
# at least gave "integer expression expected" for [ 3.4 -eq 45 ] 
dpi=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4/$(NF-1)*25.4}') # dots per inch, rounded
horizontal_relosution=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4}')

if [ $dpm -ge 8 ] && [ $horizontal_relosution -ge 2000 ];then # maybe will be run on small displays, not change default scaling in such case
    gsettings set org.cinnamon.desktop.interface scaling-factor 2
    # standard 100%, large 150%, larger 200%, largest 400%; small 66%, smaller 50%, smallest 33%
    gsettings set org.nemo.list-view default-zoom-level 'standard'
fi

# temporary to set color profiles until found a way to run on boot
$liveiso_path_scripts_root/set_color_profile.sh

    ;;
esac
EOF
    sudo chmod a+x "$file_fully_qualified_name"
fi


# to activate screensaver before suspend to try to get rid of image of the workspace displayed for a moment after resume
# Edit: did not work
#
# Trying another (seemingly advised by man pages of xscreensaver): manually running xscreensaver-systemd resulted in "failed to connect as org.freedesktop.ScreenSaver: File exists"
# meaning AFAIK Cinnamon screensaver had already registered with D-Bus and only one screensaver can do that
# TODO fix the issue mentioned in line 1 of those block of comments

# Seems running via systemd service with Before=systemd-suspend.service works, so comment out here:
#file_contents='#!/bin/sh
#
#case $1 in
#  pre)
#    xscreensaver-command -suspend
#    ;;
#  post) ;;
#esac'
#
#file_name=xscreensaver_lock_screen
#add_file_to_systemd_system-sleep
#

# to save datetime of suspend to check duration of suspend/sleep later
file_contents='#!/bin/sh

case $1 in
  pre)
    date --iso-8601=seconds | tee /tmp/amendediso_suspended_datetime.txt
    ;;
  post)
    date --iso-8601=seconds | tee --append /tmp/amendediso_suspended_datetime.txt ;;
esac'

file_name=suspended_datetime
add_file_to_systemd_system-sleep
