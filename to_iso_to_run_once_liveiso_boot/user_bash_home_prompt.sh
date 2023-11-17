#!/bin/bash

trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# ----- BASH ----- #

# ~/.bashrc contains lines that overwrite PS1 from /etc/bash.bashrc, so editing ~/.bashrc to change user prompt is needed 
# if current user is root (e.g. chrooted duriong liveUSB creation), then ~ would exist, but not /home/$(id -u -n)
if [ -e /home/$(id -u -n)/.bashrc ]; then
    echo '' >> ~/.bashrc
    echo '# bash prompt, LM original and setting it' >> ~/.bashrc
    echo '# \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$' >> ~/.bashrc
    echo 'PS1='\''\[\033[01;34m\]\w\[\033[00m\]\$ '\''' >> ~/.bashrc
fi

# ----- HOME FOLDER CHANGES ----- #

ln -s /media/ramdisk /home/$(id -u -n)/"RAM disk"
ln -s /media/zramdisk /home/$(id -u -n)/"RAM compressed"
ln -s /media/$(id -u -n) /home/$(id -u -n)/"Media"

# ----- MOUNT .CACHE TO DEDICATED TMPFS ----- #

# tmpfs use for .cache of the user is written to /etc/fstab by add_ramdisk_and_ramcache.sh, but it was not there at boot time, need to mount it after login
if [ -e /home/$(id -u -n)/.profile ]; then
    echo '' >> ~/.profile
    echo '# use RAM for cache' >> /home/$(id -u -n)/.profile
    echo "mount /home/$(id -u -n)/.cache" >> /home/$(id -u -n)/.profile
    echo '' >> /home/$(id -u -n)/.profile
fi
