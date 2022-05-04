#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# per knowledge of depeloper current code when run during liveUSB iso alteration produces errors, hence check before run
# interestingly "get"/"read" works, however "set"/"write" produces errors
# &>/dev/null gsettings set org.cinnamon.desktop.interface scaling-factor 1
# changed check to `dconf write` as gsettings exits with 0 (outputs warning) [1]
&>/dev/null dconf write /org/cinnamon/desktop/interface/scaling-factor 1
if [ $? -ne 0 ]; then
    1>&2 echo "-!- Per code and knowledge of the deleloper at time of this script was written,"
    1>&2 echo "-!- there is am indication that attempts to change dconf database here woould fail; aborting dconf_config"
    exit 1
fi

# ========= cinnamon / desktop / GUI settings ============
gsettings set org.cinnamon.control-center.display show-fractional-scaling-controls true
dpm=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4/$(NF-1)}') # dots per millimeter, rounded as bash test works with integers only
# at least gave "integer expression expected" for [ 3.4 -eq 45 ] 
dpi=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4/$(NF-1)*25.4}') # dots per inch, rounded
horizontal_relosution=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4}')

if [ $dpm -ge 8 ] && [ $horizontal_relosution -ge 2000 ];then # maybe will be run on small displays, not change default scaling in such case
    gsettings set org.cinnamon.desktop.interface scaling-factor 2
    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.0
fi
gsettings set org.cinnamon.desktop.a11y.applications screen-magnifier-enabled true
gsettings set org.cinnamon.desktop.a11y.magnifier mouse-tracking push

gsettings set org.gnome.libgnomekbd.keyboard layouts "['us', 'ru']"
# gsettings set org.gnome.libgnomekbd.keyboard options "['grp\tgrp:win_space_toggle', 'terminate\tterminate:ctrl_alt_bksp', 'grp\tgrp:lalt_lshift_toggle']"
gsettings set org.gnome.libgnomekbd.keyboard options "['grp\tgrp:win_space_toggle', 'terminate\tterminate:ctrl_alt_bksp']"

gsettings set org.cinnamon.settings-daemon.peripherals.touchpad horizontal-scrolling true

gsettings set org.nemo.desktop trash-icon-visible true

gsettings set org.nemo.list-view default-visible-columns "['name', 'size', 'type', 'date_modified', 'owner', 'permissions']"
gsettings set org.nemo.list-view default-column-order "['name', 'size', 'type', 'date_modified', 'date_created_with_time', 'date_accessed', 'date_created', 'detailed_type', 'group', 'where', 'mime_type', 'date_modified_with_time', 'octal_permissions', 'owner', 'permissions']"

# [2] in _readme.md, 
# does not work, maybe "legacy" was a hint for that, developer wants to find another way to change zoom-in for terminal
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/zoom-in/ zoom-in "<Ctrl>equal"

gsettings set org.cinnamon.desktop.screensaver lock-delay 600 # seconds, ??? start delay not found via dconf Editor
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 900 # in seconds
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800 # in seconds

# See [1] of _readme.md, also for some reason command (for binding) that have $(xrandr do not work, only specific with e.g. eDP-1,
# therefore changed script code to make shell files and bind to them - it resulted in being able to use keys to rotate system's display
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom0', 'custom1', 'custom2', 'custom3', 'custom4', 'custom5', 'custom6', 'custom7', '__dummy__']"
# or dconf write /org/cinnamon/desktop/keybindings/custom-list "['custom0', 'custom1', 'custom2', '__dummy__']"
echo 'xrandr --output $(xrandr -q|grep -v disconnected|grep connected|awk '\''{print $1}'\'') --rotate normal' | sudo tee $(get_install_path.sh)/display_rotate_normal.sh
echo 'xrandr --output $(xrandr -q|grep -v disconnected|grep connected|awk '\''{print $1}'\'') --rotate left' | sudo tee $(get_install_path.sh)/display_rotate_left.sh
echo 'xrandr --output $(xrandr -q|grep -v disconnected|grep connected|awk '\''{print $1}'\'') --rotate right' | sudo tee $(get_install_path.sh)/display_rotate_right.sh
echo 'xrandr --output $(xrandr -q|grep -v disconnected|grep connected|awk '\''{print $1}'\'') --rotate inverted' | sudo tee $(get_install_path.sh)/display_rotate_inverted.sh
sudo chmod a+rx $(get_install_path.sh)/display_rotate_normal.sh $(get_install_path.sh)/display_rotate_left.sh $(get_install_path.sh)/display_rotate_right.sh $(get_install_path.sh)/display_rotate_inverted.sh
 
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/name "'Display rotate normal'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/binding "['<Super><Alt>Up']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/command "'display_rotate_normal.sh'"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/name "'Display rotate left'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/binding "['<Super><Alt>Left']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/command "'display_rotate_left.sh'"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/name "'Display rotate right'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/binding "['<Super><Alt>Right']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/command "'display_rotate_right.sh'"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/name "'Display rotate right'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/binding "['<Super><Alt>Down']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/command "'display_rotate_inverted.sh'"

# <Primary> was Ctrl on some thinkpad
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom4/name "'Volume Up'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom4/binding "['<Primary>u']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom4/command "'pactl set-sink-volume @DEFAULT_SINK@ +25%'"

# fix TrackPoint issue om carbon X1 gen 6
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom5/name "'TrackPoint X1G6 fix'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom5/binding "['<Super><Alt>t']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom5/command "'/lib/systemd/system-sleep/trackpoint_reset key'"

# set custom screen scale
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom6/name "'Screen scale'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom6/binding "['<Super><Alt>s']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom6/command "'/lib/systemd/system-sleep/scaling_factor key'"

# screen lock binding, TODO check if xscreensaver deamon is started when ISO is booted with its debs installed
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom7/name "'Screen lock'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom7/binding "['<Super><Alt>l']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom7/command "'xscreensaver-command -lock'"

# to activate bindings (for some reason do not work just from populating dconf database from above commands), different order of items in the list
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__', 'custom0', 'custom1', 'custom2', 'custom3', 'custom4', 'custom5', 'custom6', 'custom7']"
# or dconf write /org/cinnamon/desktop/keybindings/custom-list "['__dummy__', 'custom0', 'custom1', 'custom2', 'custom3', 'custom4']"

gsettings set org.nemo.preferences show-hidden-files true
gsettings set org.nemo.preferences show-open-in-terminal-toolbar true

# sounds
dconf write /org/cinnamon/sounds/login-enabled false
dconf write /org/cinnamon/sounds/close-enabled false
dconf write /org/cinnamon/sounds/logout-enabled false
dconf write /org/cinnamon/sounds/maximize-enabled false
dconf write /org/cinnamon/sounds/unmaximize-enabled false
dconf write /org/cinnamon/sounds/minimize-enabled false
dconf write /org/cinnamon/sounds/switch-enabled false
dconf write /org/cinnamon/sounds/tile-enabled false
dconf write /org/cinnamon/sounds/plug-enabled false
dconf write /org/cinnamon/sounds/unplug-enabled true

sleep 10
exit

# add cinnamon applets to right lower panel (to the left of all the rest - clock, wifi etc.)
# does not result in panal change for some reason
# DONE: find out the reasons to the above, see below:
# result depend on speed of boot process, based on response to created github issue moved panel edit to
# editing /usr/share/glib-2.0/schemas org.cinnamon.gschema.xml or 10_cinnamon.gschema.override
# in cinnamon_config.sh
applets_orig=`dconf read /org/cinnamon/enabled-applets`
applets_changed=`echo $applets_orig | perl -pe 's/(right:)([0-9]+)/$1.($2+2)/eg' | perl -pe "s/]/, 'panel1:right:0:mem-monitor-text\@datanom.net:100', 'panel1:right:1:temperature\@fevimu:101']/"`
dconf write /org/cinnamon/enabled-applets "['']"
gsettings set org.cinnamon enabled-applets "['']"
dconf write /org/cinnamon/enabled-applets "$applets_changed"



[1]
# dconf write /org/cinnamon/desktop/interface/scaling-factor 1
error: Error spawning command line “dbus-launch --autolaunch=dafd9a61376b4676aa8b190bc1ed4b43 --binary-syntax --close-stderr”: Child process exited with code 1
root@alex-ThinkPad-slim:/# echo $?
1
root@alex-ThinkPad-slim:/# gsettings set org.cinnamon.desktop.interface scaling-factor 1

(process:242481): dconf-WARNING **: 08:34:30.432: failed to commit changes to dconf: Error spawning command line “dbus-launch --autolaunch=dafd9a61376b4676aa8b190bc1ed4b43 --binary-syntax --close-stderr”: Child process exited with code 1
root@alex-ThinkPad-slim:/# echo $?
0


