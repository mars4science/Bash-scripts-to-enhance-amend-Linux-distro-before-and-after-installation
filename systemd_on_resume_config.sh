#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# code mentioned in lauchpad bug 1791427 (for X1 carbon gen 6 with NFC to fix non working after resume trackpoint), do not know how to check for PC model, seems now do not cause problems if run for others
# TODO test if fixes the issue if run on resume as programmed here (works if run manually after full wake up)
# result of test: not working. TODO find other ways to fix automatically, for now added custom keys to activate fix code in dconf_config.sh

if [ ! -e "${liveiso_path_scripts_root}" ] ; then liveiso_path_scripts_root=/usr/bin/am-scripts ; fi

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
file_fully_qualified_name=/lib/systemd/system-sleep/$file_name

if [ -e "$file_fully_qualified_name" ];then 
    1>&2 echo "$file_fully_qualified_name exists, next is programmed not to configure code to run on resume for trackpoint issue fix"
else
    # /dev/null not to output to terminal
    echo "$file_contents" | 1>/dev/null sudo tee "$file_fully_qualified_name"
    sudo chmod a+x "$file_fully_qualified_name"
fi

# set screen scaling as dconf scaling-factor value seems to be reset on resume
file_name=scaling_factor
file_fully_qualified_name=/lib/systemd/system-sleep/$file_name

if [ -e "$file_fully_qualified_name" ];then 
    1>&2 echo "$file_fully_qualified_name exists, next is programmed not to configure code to run on resume for trackpoint issue fix"
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
fi

# temporary to set color profiles until found a way to run on boot
$liveiso_path_scripts_root/set_color_profile.sh

    ;;
esac
EOF
    sudo chmod a+x "$file_fully_qualified_name"
fi

