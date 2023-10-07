#!/bin/bash
# tested for Brave browser downloaded archive 
# trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

run_path=/media/ramdisk/w_browser
#link_path="$(get_software_path.sh)"/$(ls --sort=time "$(get_software_path.sh)" | grep w_browser | head --lines=1)
link_path="$(get_software_path.sh)"/w_browser # path to archive to extract and run

# for "install" and "update" arguments
source "$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
# help
help_message="  Runs additional browser from $run_path (first extracts that application from archive expected to be located in $link_path).
  Usage: $script_name\n"
display_help "$help_message$common_help"
# ====== #

# if does not exist locally, then copy (not expected to be run interactively therefore not listed in help message)
# man bash
# -a file True if file exists.; -h file True if file exists and is a symbolic link. -e file True if file exists.; -f file True if file exists and is a regular file.
# -a f is not negated properly as -a is also a binary and somehow binary takes precedence
# see https://unix.stackexchange.com/questions/676608/bash-negation-of-a-file-exists-does-not-change-result-whereas-for-e-chang
if [ ! -f "$link_path" ]; then
    if [ ! -d $(dirname "$link_path") ]; then sudo mkdir --parents $(dirname "$link_path"); fi
    if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
    w_browser_archive_path=$software_path_root/$(ls --sort=time $software_path_root | grep browser | head --lines=1)
    if [ ! -f "$w_browser_archive_path" ]; then echo >&2 "  ERROR/Error: file with browser to add at path : $w_browser_archive_path not found, exiting with error code 1"; exit 1; fi
    sudo cp "$w_browser_archive_path" $(dirname "$link_path")
    sudo ln -s $(dirname "$link_path")/$(basename "$w_browser_archive_path") "$link_path"
    echo copied and linked browser to "$link_path", run script again to extract to "$run_path" and start from there
    exit 0
fi

# check if run by ordinary user
if [ "$(id -u -n)" = "root" ]; then
    echo "  WARNING: Check indicates $0 is being run by '$(id -u -n)', possibly due to being run during live ISO amendment of ISO already containing the additional browser files"
    exit 0
fi

# delete previous run
if [ -d "$run_path" ]; then rm --recursive "$run_path"/*; fi

link_path=$(realpath "$link_path") # needed for grep below

# extract
if [ $(echo "$link_path" | grep ".tar") ] ; then
    tar --extract --warning=no-timestamp -f "$link_path" --atime-preserve --one-top-level="$run_path"
elif [ $(echo "$link_path" | grep ".zip") ] ; then
    unzip "$link_path" -d "$run_path"
else
    echo "Neither tar nor zip archive format for browser, exiting"; exit 1
fi

# previous variants, less general
# in case archive have single top folder where all is, assume that folder in archive include "browser" word
# browser_folder=$(ls "$run_path" | grep browser | head --lines=1)
# browser_folder=$(find "$run_path" -maxdepth 1 -type d -name *browser*)

# in case archive have single top folder where all is
if [ $(ls "$run_path" | wc | awk '{print $1}') -eq 1 ] ; then browser_folder=$(ls "$run_path"); else browser_folder=""; fi

# usually browser exec file include browser word
browser_exec_file=$(ls "$run_path/$browser_folder" | grep browser | head --lines=1)

cd "$run_path/$browser_folder"
./"$browser_exec_file" # run the browser

# now deemed not needed
# browser --register-app
# gtk-launch browser.desktop # [1] 

exit

[1]:

Where <file> is the name of the .desktop file with or without the .desktop part. The name must not include the full path.

The .desktop file must be in /usr/share/applications, /usr/local/share/applications or ~/.local/share/applications.

So gtk-launch foo opens /usr/share/applications/foo.desktop (or foo.desktop located in one of the other permitted directories.)

From gtk-launch documentation:

    gtk-launch launches an application using the given name. The application is started with proper startup notification on a default display, unless specified otherwise.

    gtk-launch takes at least one argument, the name of the application to launch. The name should match application desktop file name, as residing in /usr/share/application, with or without the '.desktop' suffix.

https://askubuntu.com/questions/5172/running-a-desktop-file-in-the-terminal
