#!/bin/bash
# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# MPV: adds config items to customize - e.g. subtitles look, runtime key bindings
app_conf_folder="/etc/mpv/"
if [ ! -e "${app_conf_folder}" ] ; then
  echo "  ERROR: ${app_conf_folder} not found; probably mpv is not installed or mpv config files location changed"
else
    # overwrite previous settings (no --append) as script may be run not one time
    file_fully_qualified_name="${app_conf_folder}"/mpv.conf
    file_contents='hwdec=auto-safe # was =vaapi, changed per `man mpv`
x11-bypass-compositor=no # or =newer; set to avoid switching of resolutions (and resulting delay) when Cinnamon is in fractional scaling mode, because when bypassing is enabled, mpv uses native resolution even in fractional scaling display mode, whereas compositor (which manages off-screen buffer for window manager) in fractional display mode uses scaled resolution; I have not noticed performance/quality issues with playing videos when set to =no; default is =fs-only (fs-only asks the window manager to disable the compositor only in fullscreen mode)

# audio-stream-silence=yes # when pausing playback, audio is not stopped, and silence is played while paused. Cash-grab consumer audio hardware (such as A/V receivers) often ignore initial audio sent over HDMI. This can happen every time audio over HDMI is stopped and resumed.

sub-font-size=45
sub-color=0.0/0.0/1.0/0.3
sub-border-size=3
sub-border-color=0.0/1.0/0.0/0.3
sub-pos=70

no-audio-display # to disable displaying of cover art when playing audio files (e.g. works for mp3)

# Options:
#  scale                          Float (0.01 to any) (default: 1.000)
#  stride                         Float (0.01 to any) (default: 60.000)
#  overlap                        Float (0 to 1) (default: 0.200)
#  search                         Float (0 to any) (default: 14.000)
#  speed                          Choices: pitch tempo none both (default: tempo)
af=scaletempo # older scaletempo might result in cleaner dialog at reduced speed

# Options:
#  search-interval                Float (1 to 1000) (default: 30.000)
#  window-size                    Float (1 to 1000) (default: 20.000)
#  min-speed                      Float (0 to 3.4028234663853e+38) (default: 0.250)
#  max-speed                      Float (0 to 3.4028234663853e+38) (default: 4.000)
# af=scaletempo2=min-speed=0.04:max-speed=25 # increase range of audio enabled speeds from default 0.25 to 4.0

fullscreen=yes'
    echo "${file_contents}" | 1>/dev/null sudo tee "${file_fully_qualified_name}"

file_fully_qualified_name="${app_conf_folder}/input.conf"
file_contents='# increase subtitle font size
ALT+k add sub-scale +0.1
# decrease subtitle font size
ALT+j add sub-scale -0.1

## Seek units are in seconds, but note that these are limited by keyframes
# Do smaller, always exact (non-keyframe-limited), seeks with shift.
# Don'\''t show them on the OSD (no-osd).
RIGHT no-osd seek  3 exact
LEFT  no-osd seek -3 exact
Shift+RIGHT no-osd seek  1 exact
Shift+LEFT  no-osd seek -1 exact
Ctrl+UP    no-osd seek  10 exact
Ctrl+DOWN no-osd seek -10 exact

/ quit # set / key to quit player
a cycle audio-pitch-correction # set "a" key to enable/disable scaletempo/scaletempo2 pitch correction for sound

# various combinations with "add sub-color" to gradually change part of RGB/transparency failed to produce desired result
ALT+3 set sub-color 1.0/0.0/0.0/0.7;set sub-border-color 0.0/1.0/1.0/0.7
ALT+e set sub-color 1.0/0.0/0.0/0.7;set sub-border-color 0.0/1.0/0.0/0.7
ALT+d set sub-color 1.0/0.0/0.0/0.7;set sub-border-color 0.0/0.0/1.0/0.7

ALT+4 set sub-color 0.0/1.0/0.0/0.7;set sub-border-color 1.0/0.0/1.0/0.7
ALT+r set sub-color 0.0/1.0/0.0/0.7;set sub-border-color 0.0/0.0/1.0/0.7
ALT+f set sub-color 0.0/1.0/0.0/0.7;set sub-border-color 1.0/0.0/0.0/0.7

ALT+5 set sub-color 0.0/0.0/1.0/0.7;set sub-border-color 1.0/1.0/0.0/0.7
ALT+t set sub-color 0.0/0.0/1.0/0.7;set sub-border-color 0.0/1.0/0.0/0.7
ALT+g set sub-color 0.0/0.0/1.0/0.7;set sub-border-color 1.0/0.0/0.0/0.7

ALT+6 set sub-color 1.0/1.0/0.0/0.7;set sub-border-color 0.0/0.0/1.0/0.7
ALT+7 set sub-color 0.0/1.0/1.0/0.7;set sub-border-color 1.0/0.0/0.0/0.7
ALT+8 set sub-color 1.0/0.0/1.0/0.7;set sub-border-color 0.0/1.0/0.0/0.7
ALT+9 set sub-color 1.0/1.0/1.0/0.7;set sub-border-color 0.0/0.0/0.0/0.7
ALT+o set sub-color 0.0/0.0/0.0/0.7;set sub-border-color 1.0/1.0/1.0/0.7


ALT+# set sub-color 1.0/0.0/0.0/0.3;set sub-border-color 0.0/1.0/1.0/0.3
ALT+E set sub-color 1.0/0.0/0.0/0.3;set sub-border-color 0.0/1.0/0.0/0.3
ALT+D set sub-color 1.0/0.0/0.0/0.3;set sub-border-color 0.0/0.0/1.0/0.3

ALT+$ set sub-color 0.0/1.0/0.0/0.3;set sub-border-color 1.0/0.0/1.0/0.3
ALT+R set sub-color 0.0/1.0/0.0/0.3;set sub-border-color 0.0/0.0/1.0/0.3
ALT+F set sub-color 0.0/1.0/0.0/0.3;set sub-border-color 1.0/0.0/0.0/0.3

ALT+% set sub-color 0.0/0.0/1.0/0.3;set sub-border-color 1.0/1.0/0.0/0.3
ALT+T set sub-color 0.0/0.0/1.0/0.3;set sub-border-color 0.0/1.0/0.0/0.3
ALT+G set sub-color 0.0/0.0/1.0/0.3;set sub-border-color 1.0/0.0/0.0/0.3

ALT+^ set sub-color 1.0/1.0/0.0/0.3;set sub-border-color 0.0/0.0/1.0/0.3
ALT+& set sub-color 0.0/1.0/1.0/0.3;set sub-border-color 1.0/0.0/0.0/0.3
ALT+* set sub-color 1.0/0.0/1.0/0.3;set sub-border-color 0.0/1.0/0.0/0.3
ALT+( set sub-color 1.0/1.0/1.0/0.3;set sub-border-color 0.0/0.0/0.0/0.3
ALT+O set sub-color 0.0/0.0/0.0/0.3;set sub-border-color 1.0/1.0/1.0/0.3'
    echo "${file_contents}" | 1>/dev/null sudo tee "${file_fully_qualified_name}"
fi

# GIMP
# GIMP2_SYSCONFDIR was not set (man gimp), so hardcode config folder
app_conf_folder="/etc/gimp/2.0/"
if [ ! -e "${app_conf_folder}" ] ; then
  echo "  ERROR: ${app_conf_folder} not found; probably GIMP is not installed or GIMP config files location changed"
else
  file_fully_qualified_name="${app_conf_folder}/gimprc"
  sudo sed --in-place 's/.*(icon-theme "Symbolic")/(icon-theme "Color")/' "${file_fully_qualified_name}" # file had got edited but GIMP started with b&w icons; when changed in GUI back and forth next time GIMP started with color icons, but in ~/.config/gimp/2.0/gimprc there was no entry for color icons added (was added when such change was made when there was no entry in system wide gimprc). TODO: understand the reason; P.S. Also GIMP initially started w/out maximazie window icon in its window. TODO: understand the reason
  sudo sed --in-place 's/.*(icon-size auto)/(icon-size huge)/' "${file_fully_qualified_name}"
fi
