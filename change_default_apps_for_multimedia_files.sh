#!/bin/bash

# trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# system wide
# /etc/gnome/defaults.list does not see to effect anything, if others are emptied, its contents did not show in Nemo
# /usr/share/applications/defaults.list is main one for defaults; in original distro some MIME types have several desktop files on the line, but adding more to the end does not effect "open with" list in Nemo, only first (left-most) is made default and used.
# On the user level defaults can be overwritten in ~/.config/mime.list, first (left-most) entry - new default, others - additional apps to add to the "open with" list
# others in "open with" list in Nemo are taken from mimeinfo.cache, which I've read is generated from desktop files located in /usr/share/applications, I have not tried to add entries to this, but emptying it resulted in emptying "open with" list in Nemo (only one "default" choise was left)

path_to_edit=/usr/share/applications/defaults.list

# use mpv instead of default others for video and audio files
sudo sed --in-place --regexp-extended -- 's/(.*)=.*io.github.celluloid_player.Celluloid.desktop.*/\1=mpv.desktop/'  "$path_to_edit"
sudo sed --in-place --regexp-extended -- 's/(.*)=.*rhythmbox.desktop.*/\1=mpv.desktop/' "$path_to_edit"

# to open srt (subtitles) in xed, not subtitle editor by default
echo 'application/x-subrip=xed.desktop' | sudo tee --append "$path_to_edit"

# open epub /ebooks with Foliate, not first app by ASCII sorted name from those in "open with" list
echo 'application/epub+zip=com.github.johnfactotum.Foliate.desktop;' | sudo tee --append "$path_to_edit"

# webp is not supported by Mint's default xviewer; pix.desktop does not list image/webp as supported MIME, but opens it
echo 'image/webp=pix.desktop;' | sudo tee --append "$path_to_edit"

# open desktop files with xed editor - noted NO effect in Nemo, still only via "Open With" context menu
echo 'application/x-desktop=xed.desktop;' | sudo tee --append "$path_to_edit"

# add xed and terminal to scripts's "open with" list in Nemo

# After both xed and terminal will be added to "open with", as org is alphabetically earlier then default is terminal unless changed, idea is to edit by default
# I noted Nemo setting in "behaviour" pertaining to execucable files are overridden when there are desktop apps to open such files
echo 'application/x-shellscript=xed.desktop;' | sudo tee --append "$path_to_edit"

path_to_edit=/usr/share/applications/org.gnome.Terminal.desktop
# add once to end of 1st section (there are empty lines between sections)
sudo sed --in-place --regexp-extended -- '0,/^$/s/^$/MimeType=application\/x-shellscript;\n/' "$path_to_edit"
# edit to run script from Nemo when choose "open with", edit one line (others are with parameters, so not selected)
sudo sed --in-place --regexp-extended -- 's/^Exec=gnome-terminal$/Exec=gnome-terminal -- bash -c '\''script="$1"; if [[ -e "$script" ]] ; then "$script" ; else exec bash ; fi '\'' bash %u/' "$path_to_edit"
path_to_edit=/usr/share/applications/xed.desktop
sudo sed --in-place --regexp-extended -- 's|MimeType=|MimeType=application/x-shellscript;|' "$path_to_edit"

# at least in chrooted system after desktop files updates mimeinfo.list was not updated automatically (and in running system at least not immediately)
sudo update-desktop-database

exit


# ------------------------------------------------------- #

# other ways below?
#user specific configs
# ~ is home, same as /home/$(id -u -n)
echo '[Default Applications]' > ~/.config/mimeapps.list

#Append all the lines containing video types to the local file:
cat "$path_to_edit" | grep video >> ~/.config/mimeapps.list

# edit in place 
sed -i -- 's/io.github.celluloid_player.Celluloid.desktop;xplayer.desktop;org.gnome.Totem.desktop/mpv.desktop/' ~/.config/mimeapps.list

echo '' >> ~/.config/mimeapps.list
echo '[Added Associations]' >> ~/.config/mimeapps.list
