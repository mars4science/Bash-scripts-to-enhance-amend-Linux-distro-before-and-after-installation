#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting $0 on error $err"; sleep 10; exit $err' ERR

# initialy was developed to apply changes after install of GNU/Linux, later used during alteration of liveUSB iso
# TODO separate into system wide and user specific scripts (user specific be run for each user)

# ---- parameters ---- #

# set variables in case run this script directly (not via _make_custom_liveusb.sh)

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; export software_path_root ; fi
if [ "x${work_path}" = "x" ] ; then work_path=/media/ramdisk ; export work_path ; fi
if [ "x${liveiso_path_scripts_root}" = "x" ] ; then liveiso_path_scripts_root=/usr/bin/am-scripts ; export liveiso_path_scripts_root ; fi

if [ ! -v locales ] ; then locales=("fr_FR" "en_US") ; # (1) variable not set, fill in: the array, list separated by space; set to empty () for not doing locales changes; correct syntax of each entry can be found in /etc/locale.gen (languagecode_COUNTRYCODE)

# ---- parameters end ---- #

# (1)
# locales if passed from `_make_custom_liveusb.sh` are in a form of "declare -a locales=([0]="A")", if locales array was set to empty, then expected to be "declare -a locales=()", if not declared at all (the script run directly), then locales variable is empty.

    export locales="${locales[@]@A}" # A operator of bash generate "declare" statement line with double quotes
fi

current_dir=`pwd`
full_path=`realpath $0` # man realpath : Print the resolved absolute file name;
dir_name=$(dirname $full_path)

#  TODO make next line redundant 
cd `dirname $0`

if [ $(ischroot;echo $?) -ne 1 ] ; then
    export running_system="false";
    echo "Seems now in chrooted environment for liveUSB ISO file creation"; sleep 2
    export LC_ALL=C.UTF-8 # added to get rid of "locale: Cannot set LC_CTYPE to default locale: No such file or directory" during debs install in case locale of chrooted is different from locale of system on which scripts are run
else
    export running_system="true"
    # turn off wireless comms to try to ensure installation does not require internet connection
    # TODO add for bluetooth, could not find how w/out tlp 2021/12/5
    nmcli radio all off
fi

# set locales
$dir_name/locales_change.sh
# locale # when run showed locale not affected by running export LC_ALL (now commented out) in the script on line directly above

# used by the rest of scripts when run with install / update arguments 
# paths are harcoded in these two scripts
$dir_name/get_install_path.sh install
$dir_name/get_source_path.sh install

$dir_name/common_arguments_to_scripts.sh install

$dir_name/binaries_install.sh # to copy misc binaries to location in $PATH
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

$dir_name/w_browser.sh install # add script to the system
# next on the first run is expected to copy archive with secondary browser from $software_path_root/... to location given by get_software_path.sh
w_browser

# after creating and writing code to copy from /bin/appimages kiwix appimage  move there, no need for special script (just put in desktop file workaround for libGL error
# Exec=bash -c "LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 kiwix-desktop_x86_64_2.1.0.appimage"
# $dir_name/k_iwix.sh install
# on the first run k_iwix is expected to copy kiwix appimage from USB (now partly hardcoded location) to location given by get_software_path.sh
# k_iwix

$dir_name/firefox-replace.sh

# install phython scripts, i.e. files.py
$dir_name/utils_misc_install.sh

# includes making ramdisk now (used in debs install)
# also kind of user specific as during liveUSB boot /etc/fstab file in squashfs gets overshadowed,
# so ramdisk need to be made after boot (one way to try is to run that script) if needed
$dir_name/to_iso_to_run_once_liveiso_boot/add_ramdisk_and_ramcache.sh

$dir_name/disable_swap.sh
$dir_name/display_backlight_control_setup.sh
$dir_name/bash_functions_and_other_config.sh

# enable packet forwarding for IPv4, IPv6
$dir_name/networking_tweaks.sh

echo "===== next in a few seconds going to install downloaded debian packages ====="
sleep 5 # pause n seconds

# install programs
# TO DO, TODO - test correctness
$dir_name/install_debs.sh
echo "===== This line is after install code, next in a few seconds going to continue ====="
sleep 5 # pause n seconds

# to be run after programs install
$dir_name/tlp_config_battery.sh
$dir_name/upower_battery_config.sh # includes change critial battery level to take action
$dir_name/change_default_apps_for_multimedia_files.sh
$dir_name/mpv_config.sh

# install gecko and mono for wine, before was separate script to run both with "source" command so that error installing 1st resulted in skipping 2nd
$dir_name/install_wine-gecko.sh
$dir_name/install_wine-mono.sh

# might try to update from Internet
$dir_name/setup_youtube-downloaders.sh

$dir_name/y_tube.sh install

# TODO add config for thinkfan 
# TODO check what thinkfan do (how interacts with manual control, e.g. via `stopfan`) as it is likely to be installed

# add applets/desklets software to Cinnamon
$dir_name/cinnamon_add_software.sh
$dir_name/cinnamon_config.sh

# copy additional color profiles
sudo cp "${software_path_root}/color-profiles/"* /usr/share/color/icc/colord

# change some text for some of the system reference manual pages to make them more easily found by apropos and for understanding; includes `updatedb` call to update database used by `locate` utility to find files.
$dir_name/man_pages_edits.sh

# to fix bug on X1 carbon gen 6 (seems not to fix the issue, maybe investigate further, for now resorted to using custom key bindings
$dir_name/systemd_on_resume_config.sh

# for liveUSB customization via chroot only
if [ $running_system = "false" ]; then
    # setup systemd service to configure user liveUSB account: "mint" (dconf, bashrc, etc) after systemd start but before user login
    $dir_name/systemd_targets_config.sh

    # fix liveUSB absense of kernel file in /boot (broken links in /boot in at least LM 20.2, get full name with version of the kernel from them via grep)
    # kernel in /boot needed for e.g. libguestfs-tools
    sudo ln -s /cdrom/casper/vmlinuz /boot/$(ls -l /boot | grep "vmlinuz " | awk '{print $11}')
fi

# for system running after install or running liveUSB 
if [ $running_system = "true" ]; then

    # for running liveUSB tweaking do not think adds any value or even might cause problems (not tested)
    if [ $(mount|grep overlay|awk '{print $1}') = "/cow" ]; then
        echo "liveUSB kind of detected, would not tweak boot as not tested for persitent liveUSB"
    else
        # add entry to start in text mode (level 3) and timeout delay change
        # TODO try to make it work for liveUSB
        $dir_name/grub_config.sh
        # to be run at the end of setup as renames /var directory which would effect some previous steps
        $dir_name/run_at_boot_config.sh
    fi

    $dir_name/to_iso_to_run_once_liveiso_boot/libvirt_access_rights.sh # for liveUSB running `--append --groups libvirt $user_name` AFAIK has no effect (need reboot or at least relogin), but ACL in /media might be useful
    $dir_name/to_iso_to_run_once_liveiso_boot/user_specific.sh # TODO: check whether safe for re-run

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

