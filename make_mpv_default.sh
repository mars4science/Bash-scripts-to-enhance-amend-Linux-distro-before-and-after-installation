#!/bin/bash

trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# ~ is home, same as /home/$(id -u -n)
echo '[Default Applications]' > ~/.config/mimeapps.list

#Append all the lines containing video types to the local file:
cat /usr/share/applications/defaults.list | grep video >> ~/.config/mimeapps.list

# edit in place 
sed -i -- 's/io.github.celluloid_player.Celluloid.desktop;xplayer.desktop;org.gnome.Totem.desktop/mpv.desktop/' ~/.config/mimeapps.list

echo '' >> ~/.config/mimeapps.list
echo '[Added Associations]' >> ~/.config/mimeapps.list



