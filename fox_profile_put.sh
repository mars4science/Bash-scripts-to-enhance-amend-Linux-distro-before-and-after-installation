#!/bin/bash
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# ====== #
source common_arguments_to_scripts.sh

# help
if [ ! $# -eq 0 ] && [ $1 = "--help" -o $1 = "-h"  -o $1 = "?" ];then
    echo "  Puts default Firefox profile on USB (/media/user_name/usb/), "
    echo "currently per available to script info (/media/$(id -un)/usb/) in tar format."
    echo "  No compression because there were issues of corruption, verification option"
    echo "is available in tar for uncompressed only."
    echo "  Usage: $script_name [e]"
    echo "optional "\""e"\"" instructs to try at the end of the script to eject and poweroff usb"
    echo "(device that in output of "\""mount"\"" contains "\""usb"\"" word)."
    exit 0
fi
# ====== #

if [ ! $# -eq 0 ] && [ $1 = "e" ];then
    to_eject="true";else to_eject="false";fi

# end firefox process just in case, $ at the end needed to skip firefox.real of tor
pkill firefox$ || pkill GeckoMain || echo there were no firefox processes to end, continue with the script

# path_original=$(pwd)

profile_path=$(cat /home/$(id -un)/.mozilla/firefox/profiles.ini | grep Default | head --lines=1 | awk --field-separator "=" '{ FS = "=" ; print $2 ; exit }') 

cd /home/$(id -un)/.mozilla/firefox/$profile_path

# sessionstore-backups needed for open tabs transfer
# the rest mot sure
# cookies.sqlite store cookies, delete after extraction if not needed to be transferred
# tar --create --verbose --bzip2 --file=/media/$(id -un)/usb/firefox-browser-profile-$profile_path-.tar.bz2 \
# encountered issues: when extracting from created archive GUI did not extract all, error was displayed. changing to no-compression and yes-verifying
# (verifying option does not work with compression - saw in output of tar when tried)
time_start=`date +%s`
archive_name=firefox-browser-profile-$profile_path-`date +'.%Y-%m-%d_%H-%M-%S.tar'`
tar --create --verbose --verify --file=/media/ramdrive/"$archive_name" \
$(find . -maxdepth 1 -type f) \
./bookmarkbackups \
./sessionstore-backups
# to make in RAM and copy took 00:00:27 vs 00:01:13 directly to USB (two times faster), leave that way
# however how about data integrity on USB, which way is "safer"?
cp /media/ramdrive/"$archive_name" /media/$(id -un)/usb
if [ $to_eject = "true" ]; then e_ject usb; fi
time_end=`date +%s`
echo
echo Backup of Firefox profile took "(hh:mm:ss):"
date --date=@$((time_end-time_start)) | awk '{print $4}' # [1]

exit

------

[1] info date

     To convert such an unwieldy number of seconds back to a more
     readable form, use a command like this:

          # local time zone used
          date -d '1970-01-01 UTC 946684800 seconds' +"%Y-%m-%d %T %z"
          1999-12-31 19:00:00 -0500

     Or if you do not mind depending on the ‘@’ feature present since
     coreutils 5.3.0, you could shorten this to:

          date -d @946684800 +"%F %T %z"
          1999-12-31 19:00:00 -0500


-----

# not needed, done by bash by default
# cd $path_original

# does & at the end needed?
firefox -no-remote -P name_of_profile 

