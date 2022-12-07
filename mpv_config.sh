#!/bin/bash
# add config for subtitles size
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

conf_file=/etc/mpv/input.conf
# first tee does not use append as script may be run not one time to change settings and it is as of now decided to overwrite previous settings
echo '# increase subtitle font size' | sudo tee $conf_file
echo 'ALT+k add sub-scale +0.1' | sudo tee --append $conf_file
echo '# decrease subtitle font size' | sudo tee --append $conf_file
echo 'ALT+j add sub-scale -0.1' | sudo tee --append $conf_file
echo '' | sudo tee --append $conf_file
echo '## Seek units are in seconds, but note that these are limited by keyframes' | sudo tee --append $conf_file
echo 'RIGHT no-osd seek  3 exact' | sudo tee --append $conf_file
echo 'LEFT  no-osd seek -1 exact' | sudo tee --append $conf_file
echo '#UP    seek  60' | sudo tee --append $conf_file
echo '#DOWN  seek -60' | sudo tee --append $conf_file
echo '# Do smaller, always exact (non-keyframe-limited), seeks with shift.' | sudo tee --append $conf_file
echo "# Don't show them on the OSD (no-osd)." | sudo tee --append $conf_file
echo 'Shift+RIGHT no-osd seek  5 exact' | sudo tee --append $conf_file
echo 'Shift+LEFT  no-osd seek -5 exact' | sudo tee --append $conf_file
echo 'Shift+UP    no-osd seek  -60 exact' | sudo tee --append $conf_file
echo 'Shift+DOWN no-osd seek 60 exact' | sudo tee --append $conf_file
echo '' | sudo tee --append $conf_file
echo '/ quit' | sudo tee --append $conf_file # set / key to quit player

conf_file=/etc/mpv/mpv.conf
echo 'sub-font-size=45' | sudo tee --append $conf_file
echo 'sub-color=0.0/1.0/1.0/0.2' | sudo tee --append $conf_file
echo 'sub-border-size=5' | sudo tee --append $conf_file
echo 'sub-border-color=0.0/0.0/0.0/0.3' | sudo tee --append $conf_file
echo 'sub-pos=70' | sudo tee --append $conf_file

echo '' | sudo tee --append $conf_file
echo 'fullscreen=yes' | sudo tee --append $conf_file

exit
# on live USB live user is made as part of boot process, 
# this script is developed tp be run at creation of USB time when user home folder does not exist
# so add all to system wide config

# user specific
conf_file=/home/$(id -un)/.config/mpv/input.conf
# user mpv folder may not exist (if mpv has never been run yet)
if [ ! -d $(dirname $conf_file) ]; then mkdir $(dirname $conf_file); fi
echo '/ quit' | sudo tee /home/$(id -un)/.config/mpv/input.conf # set / key to quit player

