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
gsettings set org.cinnamon.desktop.interface scaling-factor 2
gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.0

gsettings set org.cinnamon.desktop.a11y.applications screen-magnifier-enabled true
gsettings set org.cinnamon.desktop.a11y.magnifier mouse-tracking push

gsettings set org.gnome.libgnomekbd.keyboard layouts "['us', 'ru']"
# gsettings set org.gnome.libgnomekbd.keyboard options "['grp\tgrp:win_space_toggle', 'terminate\tterminate:ctrl_alt_bksp', 'grp\tgrp:lalt_lshift_toggle']"
gsettings set org.gnome.libgnomekbd.keyboard options "['grp\tgrp:win_space_toggle', 'terminate\tterminate:ctrl_alt_bksp']"

gsettings set org.cinnamon.settings-daemon.peripherals.touchpad horizontal-scrolling true

gsettings set org.nemo.desktop trash-icon-visible true

gsettings set org.nemo.list-view default-visible-columns "['name', 'size', 'type', 'date_modified', 'owner', 'permissions']"
gsettings set org.nemo.list-view default-column-order "['name', 'size', 'type', 'date_modified', 'date_created_with_time', 'date_accessed', 'date_created', 'detailed_type', 'group', 'where', 'mime_type', 'date_modified_with_time', 'octal_permissions', 'owner', 'permissions']"

# [2] in _readme.md
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/zoom-in/ zoom-in "<Ctrl>equal"

gsettings set org.cinnamon.desktop.screensaver lock-delay 600 # seconds, ??? start delay not found via dconf Editor
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 900 # in seconds
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800 # in seconds

# See [1] of _readme.md, also for some reason command (for binding) that have $(xrandr do not work, only specific with e.g. eDP-1,
# therefore changed script code to make shell files and bind to them - it resulted in being able to use keys to rotate system's display
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom0', 'custom1', 'custom2', 'custom3', '__dummy__']"
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

# to activate bindings (for some reason do not work just from populating dconf database from above commands), different order of items in the list
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__', 'custom0', 'custom1', 'custom2', 'custom3']"
# or dconf write /org/cinnamon/desktop/keybindings/custom-list "['__dummy__', 'custom0', 'custom1', 'custom2', 'custom3']"

gsettings set org.nemo.preferences show-hidden-files true
gsettings set org.nemo.preferences show-open-in-terminal-toolbar true

exit

[1]
# dconf write /org/cinnamon/desktop/interface/scaling-factor 1
error: Error spawning command line “dbus-launch --autolaunch=dafd9a61376b4676aa8b190bc1ed4b43 --binary-syntax --close-stderr”: Child process exited with code 1
root@alex-ThinkPad-slim:/# echo $?
1
root@alex-ThinkPad-slim:/# gsettings set org.cinnamon.desktop.interface scaling-factor 1

(process:242481): dconf-WARNING **: 08:34:30.432: failed to commit changes to dconf: Error spawning command line “dbus-launch --autolaunch=dafd9a61376b4676aa8b190bc1ed4b43 --binary-syntax --close-stderr”: Child process exited with code 1
root@alex-ThinkPad-slim:/# echo $?
0


