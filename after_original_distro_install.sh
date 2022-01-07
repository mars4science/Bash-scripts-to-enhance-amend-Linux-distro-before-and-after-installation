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

# for our old printer (TODO fix it to enable color output)
$dir_name/printer_color_as_gray.sh

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
