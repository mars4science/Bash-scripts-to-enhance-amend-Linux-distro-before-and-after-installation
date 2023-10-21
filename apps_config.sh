#!/bin/bash
# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# MPV: adds config items to customize - e.g. subtitles look, runtime key bindings
app_conf_folder="/etc/mpv/"
if [ ! -e "${app_conf_folder}" ] ; then
  echo "  ERROR: ${app_conf_folder} not found; probably mpv is not installed or mpv config files location changed"
else
    # overwrite previous settings (no --append) as script may be run not one time
    file_fully_qualified_name="${app_conf_folder}"/mpv.conf
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
    echo "${file_contents}" | 1>/dev/null sudo tee "${file_fully_qualified_name}"

    file_fully_qualified_name="${app_conf_folder}/input.conf"
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
    a cycle audio-pitch-correction # set "a" key to enable/disable scaletempo/scaletempo2 pitch correction for sound

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
