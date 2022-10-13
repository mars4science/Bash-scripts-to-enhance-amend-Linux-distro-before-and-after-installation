#!/bin/bash

# trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# alternative to youtube-dl, have read (and saw) work fast when youtube-dl is slow to download
if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi
sudo cp --no-clobber "$software_path_root"/bin/yt-dlp $(get_install_path.sh)
sudo chmod +x $(get_install_path.sh)/yt-dlp

# to setup proper python for youtube-dl
sudo ln -s /usr/bin/python3 /usr/local/bin/python

# 2021/12/12 looks like LM 20.2 distro I use contains youtube-dl
sudo cp --no-clobber "$software_path_root"/bin/youtube-dl $(get_install_path.sh)
# in /usr/bin expected to have original youtube-dl from distro, that gives error ("youtube-dl: error: youtube-dl's self-update mechanism is disabled on Debian.") when user tries to update; but in $PATH /usr/local/bin is searched before /usr/bin so as far as $(get_install_path.sh) points to /usr/local/bin one which is copied is called, not original from distro

sudo chmod +x $(get_install_path.sh)/youtube-dl

# to make it work immediately w/out bash restart
# not sure it is needed and in that form (maybe -d python?)
# The -d option causes the shell to forget remembered location of each name. 
# 2021/12/12 I have no idea where I got that it is needed here, hash adds name as time name is run (try-and-error now)
# hash -d youtube-dl #  produces  line 14: hash: youtube-dl: not found

# below does not work as expected, maybe above hash 
# does not work same as in interactive shell
# download latest (alternatively can find and copy from disk)
# sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
# would update if device is connected to the internet
# youtube-dl: error: youtube-dl's self-update mechanism is disabled on Debian.
echo next is trying to update youtube-dl, script developer has assumed it needs internet
printf "%s" "  " && sudo youtube-dl --update # even if outputs "ERROR: can't find the current version. Please try again later.", echo $? still 0, so result is seen manual way:
echo '  if no errors after "next is trying" line then updated'

