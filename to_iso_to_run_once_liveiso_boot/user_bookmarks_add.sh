#!/bin/bash

trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# adding bookmarks to Nemo is programmed based on try-and-error and https://forums.linuxmint.com/viewtopic.php?t=170398
bookmarks_file=/home/$(id -u -n)/.config/gtk-3.0/bookmarks

# noted once the script when run via autostart resulted in changes as $bookmarks_file was absent, so wait in such case
for (( i=1 ; i<10 ; i++ )) ; do 
    if [ ! -e "$bookmarks_file" ]; then sleep 1 ; else break ; fi
done

# noted that is case of large (~ 10 sec) delay new bookmarks went to "bookmarks" section of Nemo, otherwise usually to "My Computer"
sleep 5 # to increase % of cases where new bookmarks go to "bookmarks"

# in case even after delay bookmarks file was not created by the system during GUI load for the user (useful for English system interface only as for other languages some names of folders differ)
if [ ! -e "$bookmarks_file" ]; then
    mkdir --parents "$(dirname "$bookmarks_file")"
    echo "file:///home/$(id -u -n)/Documents" > "$bookmarks_file"
    echo "file:///home/$(id -u -n)/Downloads" >> "$bookmarks_file"
    echo "file:///home/$(id -u -n)/Pictures" >> "$bookmarks_file"
fi

if [[ ! $(grep "ramdisk" "$bookmarks_file") ]]; then # check if added already
    echo "file:///media/ramdisk RAM disk" >> "$bookmarks_file"
    echo "file:///media/zramdisk RAM compressed" >> "$bookmarks_file"
fi
