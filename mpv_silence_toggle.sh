#!/bin/bash

# for install, update arguments, help message output
# check for availability of common_arguments_to_scripts.sh added for Example 1 of using scripts
commons_path="$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
if [ -e "${commons_path}" ] ; then
    source "${commons_path}"
    # help
    help_message="  The Script is written to toggle mpv configuration parameter 'audio-stream-silence' to compensate for delays in audio when resuming playback over HDMI\n"
    display_help "$help_message$common_help"
else
    if [ "x$1" = "xinstall" ] ; then echo "$(basename $(realpath ${0})) is not going to be installed due to not locating common_arguments_to_scripts.sh"; exit 1; fi
fi

app_conf_folder="/etc/mpv/"
if [ ! -e "${app_conf_folder}" ] ; then
  echo "  ERROR: ${app_conf_folder} not found; probably mpv is not installed or mpv config files location changed"
else
    # overwrite previous settings (no --append) as script may be run not one time
    file_fully_qualified_name="${app_conf_folder}"/mpv.conf
    parameter_name="audio-stream-silence"
    file_contents="${parameter_name}=yes # when pausing playback, audio is not stopped, and silence is played while paused. Cash-grab consumer audio hardware (such as A/V receivers) often ignore initial audio sent over HDMI. This can happen every time audio over HDMI is stopped and resumed."
    grep --quiet "${parameter_name}" "${file_fully_qualified_name}"

    if [ $? -eq 0 ]; then # found
        grep --quiet --extended-regexp "^# *?${parameter_name}" "${file_fully_qualified_name}"
        if [ $? -eq 0 ]; then
            echo "Next line is programmed to UNcomment ${parameter_name}=yes in ${file_fully_qualified_name}"
            sudo sed --in-place --regexp-extended "s/^# *?${parameter_name}/${parameter_name}/" "${file_fully_qualified_name}"
            grep "${parameter_name}" "${file_fully_qualified_name}"
        else
            echo "Next line is programmed to Comment out ${parameter_name}=yes in ${file_fully_qualified_name}"
            sudo sed --in-place --regexp-extended "s/^.*?${parameter_name}/# ${parameter_name}/" "${file_fully_qualified_name}"
            grep "${parameter_name}" "${file_fully_qualified_name}"
        fi
    else
        echo -e "\n${file_contents}" | sudo tee --append "${file_fully_qualified_name}"
    fi    
fi

