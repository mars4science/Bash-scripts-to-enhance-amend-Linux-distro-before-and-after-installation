#!/bin/bash
# thinkpad specific
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# !!! works if device has one battery

# tlp - thinkpad ? power
# man sed: -E, -r, --regexp-extended
# ( )	Defines a marked subexpression. The string matched within the parentheses can be recalled later (see the next entry, \n). 
sudo sed -E --in-place=bak 's/#{0,1}START_CHARGE_THRESH_BAT([0-1])=[0-9]{1,3}/START_CHARGE_THRESH_BAT\1=65/' /etc/tlp.conf
sudo sed -E --in-place=bak 's/#{0,1}STOP_CHARGE_THRESH_BAT([0-1])=[0-9]{1,3}/STOP_CHARGE_THRESH_BAT\1=70/' /etc/tlp.conf

sudo sed --in-place=bak 's/#DEVICES_TO_DISABLE_ON_STARTUP="bluetooth wifi wwan"/DEVICES_TO_DISABLE_ON_STARTUP="bluetooth wifi wwan"/' /etc/tlp.conf

# --- notifies of low level of BAT0 once per crossing threshold ---

low_path=/home/$(id -un)/.cache/battery_level_low
# if [ ! -d $config_path ]; then mkdir $config_path; fi

# --dump ouputs battery percentage two times for some reason, for
# /org/freedesktop/UPower/devices/battery_BAT0
# /org/freedesktop/UPower/devices/DisplayDevice
# therefore '0,/percentage/p' selects lines from start to containing "percentage", that is only 1st output
# awk selects 2nd column, 2nd sed omits "%" sign
# upower --dump | sed -n '0,/percentage/p'| awk '/percentage:/ { print $2 }' | sed 's/%//'
# -a is binary AND, notify if <=30%, remove flag that notified is level >=31% 

# man crontab
# The entire command portion of the line, up to a newline  or  %  character,
#       will be executed by /bin/sh or by the shell specified in the SHELL variable of the crontab file.  Percent-signs (%) in the command, unless escaped with
#       backslash (\), will be changed into newline characters, and all data after the first % will be sent to the command as standard input.  There is no  way
#       to split a single command line onto multiple lines, like the shell's trailing "\".

(crontab -l 2>/dev/null; echo '* * * * * if [ ! -f '$low_path' -a  $(upower --dump | sed -n '\''0,/percentage/p'\''| awk '\''/percentage:/ { print $2 }'\'' | sed '\''s/\%//'\'') -le 30 ]; then touch '$low_path' ; XDG_RUNTIME_DIR=/run/user/$(id -u) notify-send -u normal '\''Battery level low: 30\%'\''; fi') | crontab -

(crontab -l 2>/dev/null; echo '* * * * * if [ -f '$low_path' -a  $(upower --dump | sed -n '\''0,/percentage/p'\''| awk '\''/percentage:/ { print $2 }'\'' | sed '\''s/\%//'\'') -ge 31 ]; then rm '$low_path'; fi') | crontab -

# set charge threshholds now
sudo tlp setcharge 65 70 BAT0



