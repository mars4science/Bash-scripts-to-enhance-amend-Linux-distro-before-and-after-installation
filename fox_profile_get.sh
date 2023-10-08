#!/bin/bash

trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# ====== #
source "$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
# help
help_message="  Gets Firefox profile from USB (/media/$(id -un)/usb/) tar archive and places as default profile.
  If same path already taken, asks to confirm overwrite. If declined (neither y not Y answer), does not copy.
  Usage: $script_name\n"
display_help "$help_message$common_help"
# ====== #

# man ls:
#   -t     sort by modification time, newest first

# $profile_path variable is called that name because in firefox ini file the field is named that way
# select latest backup
profile_archive_name=$(ls --sort=time /media/$(id -un)/usb | grep firefox-browser-profile | head --lines=1)
profile_path=$(echo $profile_archive_name | awk --field-separator "-" '{ FS = "-" ; print $4 ; exit }')
full_profile_path=/home/$(id -un)/.mozilla/firefox/$profile_path
profile_archive=/media/$(id -un)/usb/$profile_archive_name
profiles_ini=/home/$(id -un)/.mozilla/firefox/profiles.ini

if [ ! -d $(dirname "$full_profile_path") ]; then # looks firefox has never been run on that system
    &> /dev/null firefox & 
    # added "&> /dev/null" as firefox produces error messages, next line on start, after that on end with pkill GeckoMain
    # touch: cannot touch '/home/mint/.mozilla/93.0+linuxmint1+uma.dpkg_version': No such file or directory
    # Exiting due to channel error.
    i=1 # c style, bash can have inside "for" line and still use later
    for ((1; i <= 10; i++ ))
    do
        if [ -e $profiles_ini ]; then # I decided to try that presence of that file would be enough for subsequent copying of the profile
            i=20; break;
        fi;
        sleep 1;
    done;
    if [ $i -eq 10 ]; then echo "Takes long to start firefox, maybe run the script later?"; exit; fi
fi
# end firefox process, $ at the end needed to skip firefox.real of tor
pkill firefox$ || pkill firefox-bin$ ||pkill GeckoMain || echo there were no firefox processes to end, continue with the script

if [ -d $full_profile_path ]; then

    # https://stackoverflow.com/questions/1885525/how-do-i-prompt-a-user-for-confirmation-in-bash-script
    echo "Profile $full_profile_path exists, do you want to overwrite with"
    read -p "$profile_archive (y/n)? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # echo now going to delete all contents and extract data from archive 
        echo now going to extract data from archive overwriting some files in $full_profile_path  
        cd $full_profile_path

        # decided against removing previous files, cleaning is separate task
        # rm -fr * # no dot (starting with .) files seen, so should be enough to delete all contents
        
        # --keep-newer-files --no-overwrite-dir : decided not to use for now
        tar --extract --overwrite --file=$profile_archive
    fi

else

    cd /home/$(id -un)/.mozilla/firefox

    mkdir $profile_path && cd $_

    tar --extract --file=$profile_archive 

    # by trial and error:
    # profile should have word Profile, there should always be Profile0, 
    # looks like profiles should be sequencially numbered
    # two with same number have not resulted in error, but e.g. profile with name number as default cannot be "loaded" with `firefox -P profilename`
    # but one with different number I was able to load
    # therefore code as of now can only work to place added profile as default and previous default won't "work"
    # same name is fine too
    echo [Profile0] >> $profiles_ini
    echo Name=default >> $profiles_ini
    echo IsRelative=1 >> $profiles_ini
    echo Default=1 >> $profiles_ini
    echo Path=$profile_path >> $profiles_ini

    # several . to skip shorter Default=1 lines
    sed --in-place 's/Default=...*/Default='"$profile_path"'/' $profiles_ini

fi

exit

# not needed, done by bash by default
# cd $path_original

# does & at the end needed?
firefox -no-remote -P name_of_profile 

