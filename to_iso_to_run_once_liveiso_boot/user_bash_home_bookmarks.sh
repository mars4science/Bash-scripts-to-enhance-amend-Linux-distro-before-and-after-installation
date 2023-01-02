#!/bin/bash

trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# ----- BASH ----- #

# ~/.bashrc contains lines that overwrite PS1 from /etc/bash.bashrc, so editing ~/.bashrc to change user prompt is needed 
# if current user is root (e.g. chrooted duriong liveUSB creation), then ~ would exist, but not /home/$(id -u -n)
if [ -e /home/$(id -u -n)/.bashrc ]; then
    echo '' >> ~/.bashrc
    echo '# bash prompt, LM original and setting it' >> ~/.bashrc
    echo '# \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$' >> ~/.bashrc
    echo 'PS1='\''\[\033[01;34m\]\w\[\033[00m\]\$ '\''' >> ~/.bashrc
fi

# ----- HOME ----- #

ln -s /media/ramdisk /home/$(id -u -n)/"RAM disk"
ln -s /media/zramdisk /home/$(id -u -n)/"RAM compressed"

# ----- BOOKMARKS ----- #

# adding bookmarks to Nemo is programmed based on try-and-error and https://forums.linuxmint.com/viewtopic.php?t=170398
# not correct in case of interface language changed - TODO update bookmarks file after it was created
bookmarks_file=/home/$(id -u -n)/.config/gtk-3.0/bookmarks
if [ ! -e "$bookmarks_file" ]; then
    mkdir --parents "$(dirname "$bookmarks_file")"
    echo "file:///home/$(id -u -n)/Documents" > "$bookmarks_file"
    echo "file:///home/$(id -u -n)/Downloads" >> "$bookmarks_file"
    echo "file:///home/$(id -u -n)/Pictures" >> "$bookmarks_file"
fi

echo "file:///media/ramdisk RAM disk" >> "$bookmarks_file"
echo "file:///media/zramdisk RAM compressed" >> "$bookmarks_file"

exit

TODO

autostart_dir=/home/$(id -u -n)/.config/autostart
mkdir --parents $autostart_dir

tee $autostart_dir/bookmarks_add.desktop << EOF

[Desktop Entry]
Type=Application
Exec=/home/mint/Documents/Scripts_git-local/to_iso_to_run_once_liveiso_boot/user_bookmarks_add.sh
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name[en_US]=bookmarks_add
Comment[en_US]=No description
X-GNOME-Autostart-Delay=0

EOF

exit

# now covered in add_ramdisk_and_ramcache.sh
if [ -e /home/$(id -u -n)/.profile ]; then
    echo '' >> ~/.profile
    echo '# use RAM for cache' >> /home/$(id -u -n)/.profile
    # use "" to allow $id expand in echo
    echo "mount /home/$(id -u -n)/.cache" >> /home/$(id -u -n)/.profile
    echo '' >> /home/$(id -u -n)/.profile
fi

