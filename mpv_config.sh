#!/bin/bash
# adds config items to customize mpv - e.g. subtitles look, runtime key bindings

# trap 'err=$?; echo >&2 "Exiting $0 on error $err"; exit $err' ERR

mpv_conf_folder="/etc/mpv/"
if [ ! -e "${mpv_conf_folder}" ] ; then
  echo "  ERROR: ${mpv_conf_folder} not found; probably mpv is not installed or mpv config files location changed"
  exit
fi

# overwrite previous settings (no --append) as script may be run not one time

file_fully_qualified_name="${mpv_conf_folder}"/mpv.conf
file_contents='hwdec=vaapi
sub-font-size=45
sub-color=0.0/1.0/1.0/0.2
sub-border-size=5
sub-border-color=0.0/0.0/0.0/0.3
sub-pos=70
# older scaletempo might result in cleaner dialog at reduced speed
af=scaletempo
# increase range of audio enabled speeds from default 0.25 to 4.0
# af=scaletempo2=min-speed=0.04:max-speed=25
fullscreen=yes'
echo "$file_contents" | 1>/dev/null sudo tee "$file_fully_qualified_name"

file_fully_qualified_name="${mpv_conf_folder}"/input.conf
file_contents='# increase subtitle font size
ALT+k add sub-scale +0.1
# decrease subtitle font size
ALT+j add sub-scale -0.1

## Seek units are in seconds, but note that these are limited by keyframes
RIGHT no-osd seek  3 exact
LEFT  no-osd seek -1 exact
#UP    seek  60
#DOWN  seek -60
# Do smaller, always exact (non-keyframe-limited), seeks with shift.
# Don'\''t show them on the OSD (no-osd).
Shift+RIGHT no-osd seek  5 exact
Shift+LEFT  no-osd seek -5 exact
Shift+UP    no-osd seek  -60 exact
Shift+DOWN no-osd seek 60 exact

/ quit # set / key to quit player
$ cycle audio-pitch-correction # set $ key to enable/disable scaletempo(2) pitch correction

# various combinations with "add sub-color" to gradually change part of RGB/transparency failed to produce desired result
ALT+3 set sub-color 1.0/0.0/0.0/0.7
ALT+4 set sub-color 0.0/1.0/0.0/0.7
ALT+5 set sub-color 0.0/0.0/1.0/0.7
ALT+6 set sub-color 1.0/1.0/0.0/0.7
ALT+7 set sub-color 0.0/1.0/1.0/0.7
ALT+8 set sub-color 1.0/0.0/1.0/0.7
ALT+9 set sub-color 1.0/1.0/1.0/0.7

ALT+# set sub-color 1.0/0.0/0.0/0.2
ALT+$ set sub-color 0.0/1.0/0.0/0.2
ALT+% set sub-color 0.0/0.0/1.0/0.2
ALT+^ set sub-color 1.0/1.0/0.0/0.2
ALT+& set sub-color 0.0/1.0/1.0/0.2
ALT+* set sub-color 1.0/0.0/1.0/0.2
ALT+( set sub-color 1.0/1.0/1.0/0.2'
echo "$file_contents" | 1>/dev/null sudo tee "$file_fully_qualified_name"

exit


# on live USB live user is made as part of boot process, 
# this script is developed tp be run at creation of USB time when user home folder does not exist
# so add all to system wide config

# user specific
conf_file=/home/$(id -un)/.config/mpv/input.conf
# user mpv folder may not exist (if mpv has never been run yet)
if [ ! -d $(dirname $conf_file) ]; then mkdir $(dirname $conf_file); fi
echo '/ quit' | sudo tee /home/$(id -un)/.config/mpv/input.conf # set / key to quit player

