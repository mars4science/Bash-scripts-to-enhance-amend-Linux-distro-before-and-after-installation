#!/bin/bash

# replaces in Linux Mint modified (at least for google search) Mozilla Firefox with downloaded from Mozilla site version
# the script's code is written to process tar or zip archives with `firefox` executable to start Firefox located in root of archive or in single top folder of the archive (usually named "firefox")

ff_installed_link=$(which firefox)
# man bash:
#       -h file
#              True if file exists and is a symbolic link.
if [ -h "$ff_installed_link" ]; then ff_link_symbolic=true; else ff_link_symbolic=false; fi
# 1 argument
#                     The expression is true if and only if the argument is not null.
# therefore when $ff_installed_link is empty, then only one argument: -h so exprsssion AFAIK evaluates to true
# added "" (below too), so now expression has two arguments: -h and a string

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
ff_archive_name="$(ls --sort=time $software_path_root | grep "^firefox-" | head --lines=1)"
ff_archive=$software_path_root/$ff_archive_name
if [ ! -f "$ff_archive" ]; then echo >&2 "Firefox archive to install from not found in $software_path_root, next is exit of the script"; exit 1; fi


ff_installed_folder=$(dirname $(realpath $ff_installed_link))

# check if found folder is dedicated for firefox or as found in LM 21 it is /usr/bin, firefox application there calls somewhere (still there is similar [to ISO where firefox in /usr/bin is a link] folder /usr/lib/firefox)
if [ $(echo $ff_installed_folder | grep --ignore-case firefox) ] ; then
    echo "  Firefox has been found in the system in $ff_installed_folder, replacing is programmed in the code that follows"
    ff_toinstall_folder=$ff_installed_folder
    cd $ff_toinstall_folder
    sudo rm --recursive ./* # to replace contents of previous firefox folder
else
    ff_toinstall_folder=$liveiso_path_scripts_root/firefox
    echo "  Firefox folder has not been found in the system, adding firefox to ${liveiso_path_scripts_root} is programmed in the code that follows"
    sudo mkdir $ff_toinstall_folder # previous firefox folder not found, make somewhere safe from collision
    cd $_
fi

# extract
if [ $(echo "$ff_archive" | grep ".tar") ] ; then
    sudo tar --extract --warning=no-timestamp --file="$ff_archive" --atime-preserve --one-top-level="$ff_toinstall_folder"
elif [ $(echo "$ff_archive" | grep ".zip") ] ; then
    sudo unzip "$ff_archive" -d "$ff_toinstall_folder"
else
    echo "  ERROR: Neither tar nor zip archive format for browser, exiting"; exit 1
fi
echo "  ..found ${ff_archive} to add contents to ${liveiso_path_scripts_root}, at least that line of code is after exiting the script if archive is not found"

# in case archive have single top folder where all is
if [ $(ls "$ff_toinstall_folder" | wc | awk '{print $1}') -eq 1 ] ; then

    # ff_toinstall_folder="$ff_toinstall_folder/"$(ls "$ff_toinstall_folder");
    # now remove extra level instead:

    ff_folder_temp_name="temporary_name" # rename in case folder same as one of files - usually "firefox"
    mv "${ff_toinstall_folder}/$(ls "${ff_toinstall_folder}")" "${ff_toinstall_folder}/${ff_folder_temp_name}"
    mv "${ff_toinstall_folder}/${ff_folder_temp_name}"/* "${ff_toinstall_folder}"
    rmdir "${ff_toinstall_folder}/${ff_folder_temp_name}"
fi

# restore link that the srcipt code as written is supposed to break
if [ "$ff_link_symbolic" = "true" ]; then
    sudo ln --symbolic --force --no-target-directory $ff_toinstall_folder/firefox $ff_installed_link # adding --no-target-directory as sometimes ff_toinstall_folder points to existing directory and seems in that case ln defaults to creating link in a directory (BTW seems for bash "$a/b" in case of "a" being link to a directory resolves to "b" in that directory)
else
    # if firefox is found in delicated folder and `which firefox` is not a link, that hints that folder is in search path for executables (PATH) already
    if [[ ! ("$ff_toinstall_folder" = "$ff_installed_folder") ]]; then sudo ln --symbolic --force $ff_toinstall_folder/firefox $(get_install_path.sh) ; fi
fi

# disable updates (inc. reminders) - seems to work, checkDefaultBrowser - seems to work (both seem to work due to edit of policies.json; editing distribution.ini is left here just in case)
ff_distribution_folder=$ff_toinstall_folder/distribution
sudo mkdir --parents $ff_distribution_folder # --parents : no error if existing, make parent directories as needed
echo '{"policies": {"DisableAppUpdate": true, "DontCheckDefaultBrowser": true}}' | 1>/dev/null sudo tee $ff_distribution_folder/policies.json
echo -e '[Preferences]\napp.update.enabled=false\nbrowser.shell.checkDefaultBrowser=false' | 1>/dev/null sudo tee $ff_distribution_folder/distribution.ini

