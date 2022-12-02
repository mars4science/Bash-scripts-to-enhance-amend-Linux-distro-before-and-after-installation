#!/bin/bash

trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# system wide
# use mpv instead of default others for video and audio files
sudo sed -i -- 's/io.github.celluloid_player.Celluloid.desktop;xplayer.desktop;org.gnome.Totem.desktop/mpv.desktop/' /usr/share/applications/defaults.list

# open epub /ebooks with foliate, not first app by ASCII sorted name
echo 'application/epub+zip=com.github.johnfactotum.Foliate.desktop;' | sudo tee /usr/share/applications/defaults.list

exit

# other ways below?
#user specific configs
# ~ is home, same as /home/$(id -u -n)
echo '[Default Applications]' > ~/.config/mimeapps.list

#Append all the lines containing video types to the local file:
cat /usr/share/applications/defaults.list | grep video >> ~/.config/mimeapps.list

# edit in place 
sed -i -- 's/io.github.celluloid_player.Celluloid.desktop;xplayer.desktop;org.gnome.Totem.desktop/mpv.desktop/' ~/.config/mimeapps.list

echo '' >> ~/.config/mimeapps.list
echo '[Added Associations]' >> ~/.config/mimeapps.list



