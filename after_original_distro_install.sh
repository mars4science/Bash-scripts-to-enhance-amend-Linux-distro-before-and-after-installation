#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# TODO separate into system wide and user specific scripts (user specific be run for each user)

current_dir=`pwd`
full_path=`realpath $0` # man realpath : Print the resolved absolute file name;
dir_name=$(dirname $full_path)

#  TODO make next line redundant 
cd `dirname $0`

# test if run in chrooted environment, then I now 2021-12-22 do not think some actions are of value for such situation
# one can run `mount -t proc proc /proc` then `ps` and `mount` worked IIRC [1]
# "true" is just a string, bash test uses binary or unary operators, they return true, but true value cannot be written explicitly as I've understood many times again and again
if [ -e /proc/mounts ]; then running_system="true"; 
  else 
    echo "This line is where code is written to process liveUSB iso file creation"; 
    sleep 3;
    running_system="false"; 
    sudo mount -t proc proc /proc; 
fi

if [ $running_system = "true" ]; then
    # turn off wireless comms
    # TODO add for bluetooth, could not find how w/out tlp 2021/12/5
    nmcli radio all off
fi

# used by the rest of scripts when run with install / update arguments 
# paths are harcoded in these two scripts
$dir_name/get_install_path.sh install
$dir_name/get_source_path.sh install

$dir_name/common_arguments_to_scripts.sh install

$dir_name/fan_setup.sh # disable fan is fan control is already enabled
$dir_name/apt_get.sh install
$dir_name/r_sync.sh install
$dir_name/f_ree.sh install
$dir_name/fox_profile_put.sh install
$dir_name/fox_profile_get.sh install
$dir_name/fox_tabs_put.sh install
$dir_name/fox_tabs_get.sh install
$dir_name/git_clone.sh install
$dir_name/git_compact.sh install
$dir_name/get_software_path.sh install
$dir_name/t_or.sh install
# on the first run t_or is expected to copy tor bundle from USB (now partly hardcoded location) to location given by get_software_path.sh
t_or

$dir_name/firefox-replace.sh


# includes making ramdrive now (used in debs install)
$dir_name/add_ramdisk_and_ramcache_permanently_to_fstab.sh
$dir_name/disable_swap.sh
$dir_name/memory_notify_config.sh
$dir_name/after_login_config.sh
$dir_name/display_backlight_control.sh

echo "===== next in a few seconds going to install downloaded debian packages ====="
sleep 5 # pause n seconds

# install programs
# TO DO, TODO - test correctness
$dir_name/install_debs.sh
echo "===== This line is after install code, next in a few seconds going to continue ====="
sleep 5 # pause n seconds

# to be run after programs install
$dir_name/tlp_config_battery.sh
$dir_name/upower_battery_config.sh # inc. change critial battery level to take action
$dir_name/make_mpv_default.sh
$dir_name/add_mpv_config_for_subtitles.sh
$dir_name/after_wine_install.sh # installs gecko and changes default app for ini files back to xed.desktop

# would try to update from Internet
$dir_name/setup_youtube-dl.sh
$dir_name/y_tube.sh install

# TODO add config for thinkfan 
# TODO check what thinkfan do (how interacts with manual control, e.g. via `stopfan`)as it is likely to be installed 

# for our old printer (TODO fix printer to enable color output)
$dir_name/printer_color_as_gray.sh

# rus locale has been added at install time, but for liveUSB need to add separately
sudo locale-gen ru_RU
sudo locale-gen ru_RU.UTF-8

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

gsettings set org.nemo.desktop visible-trash-icon true

gsettings set org.nemo.list-view default-visible-columns "['name', 'size', 'type', 'date_modified', 'owner', 'permissions']"
gsettings set org.nemo.list-view default-column-order "['name', 'size', 'type', 'date_modified', 'date_created_with_time', 'date_accessed', 'date_created', 'detailed_type', 'group', 'where', 'mime_type', 'date_modified_with_time', 'octal_permissions', 'owner', 'permissions']"

# [2] in _readme.md
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/zoom-in/ zoom-in "<Ctrl>equal"

gsettings set org.cinnamon.desktop.screensaver lock-delay 600 # seconds, ??? start delay not found via dconf Editor
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 900 # in seconds
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800 # in seconds

# See [1] of _readme.md, also for some reason command (for binding) that have $(xrandr  do not work, only specific with e.g. eDP-1
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

git config --global color.status.changed yellow
git config --global color.diff.old yellow

# ========= end of configs / settings =============

if [ $running_system = "true" ]; then

    # for liveUSB tweaking do not think adds any value or even might cause problems (not tested)
    if [ $(mount|grep overlay|awk '{print $1}') = "/cow" ]; then
        echo "liveUSB kind of detected, would not tweak boot as not tested for persitent liveUSB"
    else
        # add entry to start in text mode (level 3) and timeout delay change
        # TODO try to make work fot liveUSB
        $dir_name/grub_config.sh
        # to be run at the end of setup as renames /var directory which would effect some previous steps
        $dir_name/run_at_boot_config.sh
    fi

    # to leave terminal open with interactive bash if started from GUI
    # ps output list processes' paths as called (relative), so use "$0" 
    ps --sort +pid -eo pid,stat,command | grep "$0" | head -1 | awk '{print $2}' | grep "s" > /dev/null # man ps : s    is a session leader
    if [ $? -eq 0 ]; then bash -i; fi
fi

exit

# TODO reload ./bashrc
# https://stackoverflow.com/questions/2518127/how-to-reload-bashrc-settings-without-logging-out-and-back-in-again
# source ~/.bashrc # to update changes in running terminal
# above line make changes only in bash running the script which exits after script completion
# maybe some combination with exec "$BASH" or exec scriptname - what I've tried did not work as hoped for as of now ...


[1]

root@alex-ThinkPad-slim:/# ps
Error, do this: mount -t proc proc /proc
root@alex-ThinkPad-slim:/# mount
mount: failed to read mtab: No such file or directory
