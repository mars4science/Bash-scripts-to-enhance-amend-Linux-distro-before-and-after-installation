#!/bin/bash

trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# TODO think about hardcoded copyfrom_path

run_path=/media/ramdrive
link_path="$(get_software_path.sh)"/tor.tar.xz

# for "install" and "update" arguments
source common_arguments_to_scripts.sh
# help
help_message="  Runs tor browser from $run_path (first extracts that application from archive expected to be located in $link_path).
  Usage: $script_name\n"
display_help "$help_message$common_help"
# ====== #

# if does not exist locally, then copy (not expected to be run interactively therefore not listed in help message)
# man bash
# -a file True if file exists.; -h file True if file exists and is a symbolic link. -e file True if file exists.;
# -a f is not negated properly as -a is also a binary and somehow binary takes precedence
# see https://unix.stackexchange.com/questions/676608/bash-negation-of-a-file-exists-does-not-change-result-whereas-for-e-chang
if [ ! -e "$link_path" ]; then
    if [ ! -d $(dirname "$link_path") ]; then sudo mkdir $(dirname "$link_path"); fi
    if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi
    copyfrom_path="$software_path_root/tor-browser-linux64-10.5.10_en-US.tar.xz"
    if [ ! -e "$copyfrom_path" ]; then echo >&2 "tor path $copyfrom_path not found, exiting with error"; exit 1; fi
    sudo cp "$copyfrom_path" $(dirname "$link_path")
    sudo ln -s $(dirname "$link_path")/$(basename "$copyfrom_path") $link_path
    echo copied and linked tor to "$link_path", run script again to copy to RAM and start from there
    exit 0
fi

# delete previous run
if [ -d $run_path/tor-browser_en-US ]; then rm --recursive $run_path/tor-browser_en-US; fi

cp --dereference "$link_path" $run_path
7z e -o"$run_path" "$run_path"/tor.tar.xz
rm "$run_path"/tor.tar.xz
# 7z does not restore permissions
# 7z x -o"$run_path" "$run_path"/tor*.tar
tar x -f "$run_path"/tor.tar --atime-preserve --one-top-level="$run_path"
rm "$run_path"/tor.tar

"$run_path"/tor-browser_en-US/Browser/start-tor-browser --register-app
gtk-launch start-tor-browser.desktop

exit

Notes:

Where <file> is the name of the .desktop file with or without the .desktop part. The name must not include the full path.

The .desktop file must be in /usr/share/applications, /usr/local/share/applications or ~/.local/share/applications.

So gtk-launch foo opens /usr/share/applications/foo.desktop (or foo.desktop located in one of the other permitted directories.)

From gtk-launch documentation:

    gtk-launch launches an application using the given name. The application is started with proper startup notification on a default display, unless specified otherwise.

    gtk-launch takes at least one argument, the name of the application to launch. The name should match application desktop file name, as residing in /usr/share/application, with or without the '.desktop' suffix.




https://askubuntu.com/questions/5172/running-a-desktop-file-in-the-terminal

#man bash
# file1 -nt file2
#      True if file1 is newer (according to modification date) than file2, or if file1 exists and file2 does not.
# file1 -ot file2
#      True if file1 is older than file2, or if file2 exists and file1 does not.

# man rsync
# A trailing slash on the source changes this behavior to avoid creating an additional directory  level
# at  the destination.  You can think of a trailing / on a source as meaning "copy the contents of this
# directory" as opposed to "copy the directory by name"
