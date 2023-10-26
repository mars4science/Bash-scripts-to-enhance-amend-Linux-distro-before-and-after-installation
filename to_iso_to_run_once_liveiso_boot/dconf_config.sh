#!/bin/bash
# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; sleep 10; exit $err' ERR

# dbus-run-session needs to be used to run the script (to write to dconf database) before user login, for liveUSB the script is run from systemd_to_run_as_user.sh [1]

&>/dev/null dconf write /org/cinnamon/desktop/interface/scaling-factor 1
if [ $? -ne 0 ]; then
    1>&2 echo "-!- Per code and knowledge of the deleloper at time of this script was written,"
    1>&2 echo "-!- there is am indication that attempts to change dconf database here woould fail; aborting dconf_config"
    exit 1
fi

# NOTE: dconf: VALUE arguments must be in proper GVariant format (e.g. a string must include explicit quotes - either single or double - around the string: e.g. foo as "'foo'", f'o"o as '"f'\''o\"o"').

# ========= cinnamon / desktop / GUI settings ============
# LM 21 ?
gsettings set org.cinnamon.control-center.display show-fractional-scaling-controls true
# LM 21.2
gsettings set org.cinnamon.muffin experimental-features "['x11-randr-fractional-scaling']"

# moved to gui_configure.sh
#dpm=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4/$(NF-1)}') # dots per millimeter, rounded as bash test works with integers only at least gave "integer expression expected" for [ 3.4 -eq 45 ]
#dpi=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4/$(NF-1)*25.4}') # dots per inch, rounded
#horizontal_resolution=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4}')
#
# "gsettings set org.cinnamon.desktop.interface scaling-factor 2" does not seem to work in LM 21 (had been working in LM 20); GUI scaling controls worked in both
#if [ $dpm -ge 6 ] && ([ ${horizontal_resolution} -le 2000 ] || [ ${horizontal_resolution} -ge 3500 ]); then
#    # increase text scaling for primary fullhd and 4k displays; TL;DR:
#    # 14 inch is 309mm width, hd is 1920, dpm=6.21
#    # text scaling setting below is based on observation, but source code and/or documentation:
#    # 1. if resolution is larger than 1920 seems whole dislay scaling is set to 2 by LM somewhere in code. TODO find where and how
#    # 2. if resolution is less than 1920 seems whole dislay scaling is set to 1
#    # 3. Text scaling results in half effect, e.g. scaling increase from 1.0 to 1.5 resulted in ~ 1.25 font size increase in list view in Nemo
#    # 4. Decreasing scaling below 1 had not resulted in icons decrease in Nemo's list view, increasing above 1 had increased icons size
#    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.5
#fi

gsettings set org.cinnamon.desktop.a11y.applications screen-magnifier-enabled true
gsettings set org.cinnamon.desktop.a11y.magnifier mouse-tracking push

# gsettings set org.gnome.libgnomekbd.keyboard layouts "['us', 'fr', 'de']" # now set in locales_change.sh and tha t script edits this line for liveISO
# gsettings set org.gnome.libgnomekbd.keyboard options "['grp\tgrp:win_space_toggle', 'terminate\tterminate:ctrl_alt_bksp', 'grp\tgrp:lalt_lshift_toggle']"
gsettings set org.gnome.libgnomekbd.keyboard options "['grp\tgrp:win_space_toggle', 'grp\tgrp:ctrls_toggle', 'terminate\tterminate:ctrl_alt_bksp']"

# change keyboard layout icon in cinnamon panel to upper font text
gsettings set org.cinnamon.desktop.interface keyboard-layout-show-flags false
gsettings set org.cinnamon.desktop.interface keyboard-layout-use-upper true

# Nemo
gsettings set org.nemo.preferences show-hidden-files true
gsettings set org.nemo.preferences show-advanced-permissions true # Show advanced permissions in the file property dialog
gsettings set org.nemo.preferences show-open-in-terminal-toolbar true
gsettings set org.nemo.desktop trash-icon-visible true

gsettings set org.nemo.list-view default-visible-columns "['name', 'size', 'type', 'date_modified', 'date_accessed', 'owner', 'permissions']"
gsettings set org.nemo.list-view default-column-order "['name', 'size', 'date_modified', 'date_created_with_time', 'date_accessed', 'date_created', 'type', 'detailed_type', 'group', 'where', 'mime_type', 'date_modified_with_time', 'octal_permissions', 'owner', 'permissions']"
gsettings set org.nemo.search search-visible-columns "['name', 'where', 'date_modified', 'size', 'type', 'owner', 'permissions']"

gsettings set org.nemo.preferences default-folder-viewer 'list-view'
# standard 100%, large 150%, larger 200%, largest 400%; small 66%, smaller 50%, smallest 33%
gsettings set org.nemo.list-view default-zoom-level 'standard'
gsettings set org.nemo.icon-view default-zoom-level 'largest'

gsettings set org.nemo.preferences executable-text-activation 'display' # What to do with executable text files when they are activated (single or double clicked). Possible values are "launch" to launch them as programs, "ask" to ask what to do via a dialog, and "display" to display them as text files.
# seems to not have effect if "open with" and/or default desktop application is set for x-shellscript files (see change_default_apps_for_multimedia_files.sh)
gsettings set org.nemo.preferences click-double-parent-folder true # If true, double click left on blank area will go to parent folder
gsettings set org.nemo.preferences quick-renames-with-pause-in-between true # Enables renaming of icons by two times clicking with pause between clicks
gsettings set org.nemo.preferences date-format 'iso' # to set time to 24 hours; e.g. 2023-01-17 15:00:00

# peripherals, changed schema from LM 20.2 to LM 21
gsettings set org.cinnamon.settings-daemon.peripherals.mouse double-click 550 # to ensure double click don't activate rename - increase default (400)
if [ $? -ne 0 ] ; then # noted above schema depricated for Linux Mint 21
    echo " next line try org.cinnamon.desktop.peripherals.mouse instead"
    gsettings set org.cinnamon.desktop.peripherals.mouse double-click 550
fi
gsettings set org.cinnamon.settings-daemon.peripherals.touchpad horizontal-scrolling true
if [ $? -ne 0 ] ; then # noted above schema depricated for Linux Mint 21 and no such key, experiment showed that horizontal-scrolling works, setting key left just in case setting will be re-introduced
    echo " next line try org.cinnamon.desktop.peripherals.touchpad instead"
    gsettings set org.cinnamon.desktop.peripherals.touchpad horizontal-scrolling true
fi
gsettings set org.cinnamon.settings-daemon.peripherals.touchpad tap-to-click true # noted: false by default for Linux Mint 21
if [ $? -ne 0 ] ; then # noted above schema depricated for Linux Mint 21
    echo " next line try org.cinnamon.desktop.peripherals.touchpad instead"
    gsettings set org.cinnamon.desktop.peripherals.touchpad tap-to-click true
fi

gsettings set org.cinnamon.desktop.media-handling automount false # If set to true, then Nautilus will automatically mount media such as user-visible hard disks and removable media on start-up and media insertion.
gsettings set org.cinnamon.desktop.media-handling automount-open false # Whether to automatically open a folder for automounted media (happens in Nemo)
gsettings set org.cinnamon.desktop.media-handling autorun-never true # If set to true, then Nautilus will never prompt nor autorun/autostart programs when a medium is inserted.

# gnome-system-monitor
gsettings set org.gnome.gnome-system-monitor show-whose-processes 'all' # Determines which processes to show
gsettings set org.gnome.gnome-system-monitor cpu-smooth-graph 'false' # Show CPU chart as smooth graph using Bezier curves
gsettings set org.gnome.gnome-system-monitor update-interval 5000 # Time in milliseconds between updates of the process view (if 1 second than often processes reorder so frequently it is difficult to select needed one)
gsettings set org.gnome.gnome-system-monitor process-memory-in-iec true # Show memory in IEC (that is in e.g. MiB, not MB)
gsettings set org.gnome.gnome-system-monitor graph-update-interval 2000 # Time in milliseconds between updates of the graphs
gsettings set org.gnome.gnome-system-monitor graph-data-points 250 # Time amount of data points in the resource graphs (no scrolling, affects scale)
gsettings set org.gnome.gnome-system-monitor kill-dialog true # Show warning dialog when killing processes
gsettings set org.gnome.gnome-system-monitor.proctree col-14-visible 'true' # Show process “Command Line” column on startup
gsettings set org.gnome.gnome-system-monitor.proctree col-14-width 120 # Width of process “Command Line” column
gsettings set org.gnome.gnome-system-monitor.proctree col-4-visible 'true' # Show process “Resident Memory” column on startup
gsettings set org.gnome.gnome-system-monitor.proctree col-4-width 90 # Width of process “Resident Memory” column
gsettings set org.gnome.gnome-system-monitor.proctree col-2-visible 'true' # Show process “Status” column on startup
gsettings set org.gnome.gnome-system-monitor.proctree col-2-width 65 # Width of process “Status” column
gsettings set org.gnome.gnome-system-monitor.proctree sort-col 8 # CPU %
gsettings set org.gnome.gnome-system-monitor.proctree sort-order 0 # highest at top

# [2] in _readme.md ([2] no longer there, what was it?)
# does not work, maybe "legacy" was a hint for that, developer wants to find another way to change zoom-in for terminal
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/zoom-in/ zoom-in "<Ctrl>equal"

#
# screensaver settings
#
# gsettings set org.cinnamon.desktop.screensaver idle-activation-enabled false # setting had not turned off activation, setting idle-delay to 0 turned off
gsettings set org.cinnamon.desktop.session idle-delay 0 # 0 displayed as "Never" by GUI in Screensaver->Settings; setting in seconds
gsettings set org.cinnamon.desktop.screensaver lock-delay 600 # seconds
# gsettings set org.cinnamon.desktop.screensaver custom-screensaver-command "'sh -c \'xscreensaver-command -lock || ( ( xscreensaver & ) && sleep 1 && xscreensaver-command -lock )\''" # interestingly when xscreensaver is activated by cinnamon.desktop based on idle-delay, lockTimeout in .xscreensaver seems to have no effect (TODO: try to find out why and how to fix), lock happened ealier (immediately?) (and org.cinnamon.desktop.screensaver lock-delay was 10 minutes), therefore not using for now; also allow-keyboard-shortcuts does not seem to enable custom keyboard bindings to work when xscreensaver locked the screen
# gsettings set org.cinnamon.desktop.screensaver allow-media-control true
# gsettings set org.cinnamon.desktop.screensaver allow-keyboard-shortcuts true


gsettings set org.cinnamon.settings-daemon.plugins.power lock-on-suspend false # in GUI it is in screensaver settings window, diaable as reported workaround for reported bug of scale reset after suspend on Linux Mint 21 (bundled screensaver does not lock screen when booted as liveUSB, xscreensaver does and has many programs/themes)
# gsettings set org.cinnamon.settings-daemon.plugins.power lid-close-suspend-with-external-monitor true # added but as commented out because not sure if better to suspend than not
gsettings set org.cinnamon.desktop.screensaver show-album-art false # to remote sometimes displyed youtube video picture from the screen
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 900 # in seconds
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800 # in seconds
gsettings set org.cinnamon.settings-daemon.plugins.power idle-dim-time 300 # in seconds, dim screen after becoming idle; timeout
gsettings set org.cinnamon.settings-daemon.plugins.power idle-brightness 10 # in %

#
##### beginning of keyboard bindings #####

# previous notes and code see in [3]

# programmed based on output of `dconf watch /` when adding key via GUI:
# upon new entry added in GUI addional entry to custom-list is added to the right (1st part, setting mane and command) and after binding added in GUI the list's order is reversed (2nd part)
# 1st entry is exception: custom0 is added to the left

# WARNING: when binding overwrites some "standard" binding in GUI, additional is caught by dconf watch: setting standard to empty, e.g. /org/cinnamon/desktop/keybindings/media-keys/volume-up-quiet when reassigning Alt+AudioRaiseVolume
#   assigning same combination to custom as used by another custom resulted in both custom entries having that keys
#   When this code tried to assign binding used by "standard" to custom (Alt+AudioRaiseVolume / Alt+AudioLowerVolume) w/out setting standard to empty, there were appearently random results:
# AudioRaiseVolume/AudioLowerVolume mystery:
#   Done dozens of tests creating new user, running dconf (including having only two add_key function calls and close to nothing else) for it and starting Cinnamon; keys ['<Alt>AudioRaiseVolume'] and ['<Alt>AudioLowerVolume'] worked appearently randomly: 1st in add_key list, 2nd, both, none. Even adding delay of 5 seconds between add_key calls later some seconds after each of two parts of binding calls in add_key function itself had not helped, using 'gsettings set' instead of 'dconf write' had not helped.

# FIX: if such issue occured, working of custom keys was successfully completed after Cinnamon start by running "keybindings_to_reverse_custom_list.sh" (assigned to keys below)

# Note: if as dconf watch outputted /org/cinnamon/desktop/keybindings/media-keys/volume-up-quiet; dconf read of the key may result in empty output, whereas `gsettings get org.cinnamon.desktop.keybindings.media-keys volume-up-quiet` resulted in expected output

# Note: dconf watch output when assigning custom in GUI was ['<Alt>AudioRaiseVolume'], where as `gsettings get org.cinnamon.desktop.keybindings.media-keys volume-up-quiet` output was ['<Alt>XF86AudioRaiseVolume']; assigning via `dconf write` to custom w/out XF86 works

# Note: Alternatively maybe done using gsettings like below, need schema+key not just key as dconf, also no gsettings schema for '/org/cinnamon/desktop/keybindings/custom-keybindings/custom', hence AFAIK need for such long lines TODO understand why
# gsettings_customb_path='org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom'
# gsettings set "${gsettings_customb_path}${id_key}/" command "${3}"

# Note: when keyboard dialog gets opened in GUI, below key-value pairs are in output of dconf watch, just in case here
# dconf write /org/cinnamon/desktop/peripherals/keyboard/delay 'uint32 500'
# dconf write /org/cinnamon/desktop/interface/cursor-blink-time 1200
# dconf write /org/cinnamon/desktop/peripherals/keyboard/repeat-interval 'uint32 30'

id_key=-1
dconf_customb_path='/org/cinnamon/desktop/keybindings/custom-keybindings/custom'
custom_list="['__dummy__']"

add_key(){

    id_key=$((id_key+1))
    if [ ${id_key} -eq 0 ]; then # initialization of the list ? as reason for exception TODO understand if and why needed
        custom_list="$(python -c "a=${custom_list};a.insert(0,'custom${id_key}');print(a)")" # added to the left
    else
        custom_list="$(python -c "a=${custom_list};a.append('custom${id_key}');print(a)")" # added to the right
    fi

    # using dconf
    dconf write /org/cinnamon/desktop/keybindings/custom-list "${custom_list}"
    dconf write "${dconf_customb_path}${id_key}/binding" "@as []" # per GVariant Format Strings syntax need to specify type for empty array; '@as' means (developer's guess) 's' for string and 'a' for array
    dconf write "${dconf_customb_path}${id_key}/command" "${3}"
    dconf write "${dconf_customb_path}${id_key}/name" "${1}"

    dconf write "${dconf_customb_path}${id_key}/binding" "${2}"
    custom_list="$(python -c "a=${custom_list};a.reverse();print(a)")" # (echo "" | python) works too, but why make extra subshells?
    dconf write /org/cinnamon/desktop/keybindings/custom-list "${custom_list}"
}

# hack to fix bindings to be assigned to already used key combinations; TODO maybe add autostart item for Cimmanon, but for now no automatic as it may be useful to know if the code tries to replace keys
key_script_name="keybindings_to_reverse_custom_list.sh"
if [ ! -e "$(get_install_path.sh)/${key_script_name}" ]; then
    echo 'dconf write /org/cinnamon/desktop/keybindings/custom-list "$(python -c "a=$(dconf read /org/cinnamon/desktop/keybindings/custom-list);a.reverse();print(a)")"' | sudo tee $(get_install_path.sh)/${key_script_name}
    sudo chmod a+rx $(get_install_path.sh)/${key_script_name}
fi
add_key "'To reverse keybindings custom list'" "['<Super><Alt>r']" "'${key_script_name}'"

# around {print $1} single quotes need NOT be quoted for bash as within double quotes, but to be 1) outside of single quotes for sh (' -> '\''), 2) backslash used for (1) be escaped for GVariant, using unicode \u005c works for GVariant, alternatively \\\\, 3) all resultant single quotes to be quoted for GVariant (' -> \')
# $ to be quoted (e.g. via backslash) as within double quotes for bash
add_key "'Display rotate normal'" "['<Super><Alt>Up']" "'sh -c \'xrandr --output \$(xrandr -q|grep -v disconnected|grep connected|awk \'\u005c\'\'{print \$1}\'\u005c\'\') --rotate normal\''"
add_key "'Display rotate left'" "['<Super><Alt>Left']" "'sh -c \'xrandr --output \$(xrandr -q|grep -v disconnected|grep connected|awk \'\u005c\'\'{print \$1}\'\u005c\'\') --rotate left\''"
add_key "'Display rotate right'" "['<Super><Alt>Right']" "'sh -c \'xrandr --output \$(xrandr -q|grep -v disconnected|grep connected|awk \'\u005c\'\'{print \$1}\'\u005c\'\') --rotate right\''"
add_key "'Display rotate upsidedown'" "['<Super><Alt>Down']" "'sh -c \'xrandr --output \$(xrandr -q|grep -v disconnected|grep connected|awk \'\u005c\'\'{print \$1}\'\u005c\'\') --rotate inverted\''"

add_key "'Volume Up'" "['<Primary>AudioRaiseVolume']" "'pactl set-sink-volume @DEFAULT_SINK@ +6dB'" # set key to up volume above 100% by increasing voltage 2x (+6dB doubles voltage according to wiki page)
add_key "'Volume Down'" "['<Primary>AudioLowerVolume']" "'pactl set-sink-volume @DEFAULT_SINK@ -6dB'" # set key to lower volume by decreasing voltage 2x (-6dB halves voltage according to wiki page)

add_key "'TrackPoint X1G6 fix'" "['<Super><Alt>t']" "'/lib/systemd/system-sleep/trackpoint_reset key'" # fix TrackPoint issue om carbon X1 gen 6
add_key "'Screen lock'" "['<Super><Alt>x']" "'sh -c \'xscreensaver-command -lock || ( ( xscreensaver & ) && sleep 1 && xscreensaver-command -lock )\''" # screen lock binding, xscreensaver to be set to be started via other script

add_key "'Brightness up'" "['<Alt>MonBrightnessUp']" "'night +1'" # set custom monitor brightness adjustments
add_key "'Brightness down'" "['<Alt>MonBrightnessDown']" "'night -1'"

add_key "'Help'" "['F1']" "'notify-send \'NoNo help in GUI available, some info via man pages\''" "'yelp'" # GUI help app (not included in the distro: to be istalled) replaces opening Linux Mint web page on F1 press
add_key "'Air fan(s) off'" "['<Super><Alt>z']" "'stopfan'"

add_key "'Up text scaling 1.1 times'" "['<Primary><Shift><Alt>x']" '"sh -c '\''f=$(gsettings get org.cinnamon.desktop.interface text-scaling-factor);fnew=$(printf \"print(${f}*1.1)\" | python); gsettings set org.cinnamon.desktop.interface text-scaling-factor ${fnew}'\'\"
add_key "'Up text scaling 0.9 times'" "['<Primary><Shift><Alt>z']" '"sh -c '\''f=$(gsettings get org.cinnamon.desktop.interface text-scaling-factor);fnew=$(printf \"print(${f}*0.9)\" | python); gsettings set org.cinnamon.desktop.interface text-scaling-factor ${fnew}'\'\"

# did not work on LM 21 so commented out, moved to use font scaling mostly
# add_key "'Screen scale'" "['<Super><Alt>s']" "'/lib/systemd/system-sleep/scaling_factor key'" # set custom screen scale

##### end of keyboard bindings #####
#

# additional shortcuts for working with windows
# <Primary> was Ctrl on some thinkpad
gsettings set org.cinnamon.desktop.keybindings.wm close "['<Alt>F4', '<Primary><Shift>w']" # same as in terminal
gsettings set org.cinnamon.desktop.keybindings.wm maximize "['<Alt><Shift>Up']"
gsettings set org.cinnamon.desktop.keybindings.wm minimize "['<Alt><Shift>Down']"

# sounds
dconf write /org/cinnamon/sounds/login-enabled false
dconf write /org/cinnamon/sounds/close-enabled false
dconf write /org/cinnamon/sounds/logout-enabled false
dconf write /org/cinnamon/sounds/maximize-enabled false
dconf write /org/cinnamon/sounds/unmaximize-enabled false
dconf write /org/cinnamon/sounds/minimize-enabled false
dconf write /org/cinnamon/sounds/switch-enabled false
dconf write /org/cinnamon/sounds/tile-enabled false
dconf write /org/cinnamon/sounds/plug-enabled false
dconf write /org/cinnamon/sounds/unplug-enabled false
# DONE: find how to disable notification's sound (is on by default in LM 21.2)
# interestingly if value in dconf GUI is set to 'default', `dconf read /org/cinnamon/sounds/notification-enabled` outputs nothing, but gsetting get outputs correct default value; however in such setting `dconf write` works.
# TODO: find out how to change 'default' flag via terminal, also how to read 'Summary', 'Description' fields of dconf entry
dconf write /org/cinnamon/sounds/notification-enabled false

gsettings set ca.desrt.dconf-editor.Settings show-warning false # If “true”, Dconf Editor opens a popup when launched reminding the user to be careful.
gsettings set org.gnome.nm-applet disable-disconnected-notifications true # Set this to true to disable notifications when disconnecting from a network.

desktop_background=liveiso_path_settings_root/background.jpg
if [ ! -e "$desktop_background" ] ; then desktop_background=/usr/share/backgrounds/linuxmint-ulyssa/echerkasski_countryside.jpg ; fi
gsettings set org.cinnamon.desktop.background picture-uri 'file://'"$desktop_background"

# UPDATE: setting not helping for some reason
gsettings set org.mate.applications-browser exec 'mozilla' # Default browser for URLs (to try to cancel firefox prompt to make it default at the first run)

# change theme for Cinnamon
gsettings set org.cinnamon.desktop.interface gtk-theme 'Mint-Y-Dark'
gsettings set org.cinnamon.desktop.interface icon-theme 'Mint-Y-Dark-Teal' # noted Mint-Y appearance changed from LM 21 to 21.2 from yellowish to greenish, so now attemping to use more "specifc" themes, on 21.2 result of 'Mint-Y-Dark-Teal' is interesting even as there seems to be no such theme available for choosing in GUI
gsettings set org.cinnamon.theme name 'Mint-Y-Dark'

# change theme for xed to Cobalt (for dark Cinnamon theme)
gsettings set org.x.editor.preferences.editor scheme 'cobalt'
gsettings set org.x.editor.preferences.editor display-line-numbers false # AFAIK false by default, however added as could be useful to set to true for somebody

exit



[1]
# Issue solved by running the script via:
sudo -i --user=mint bash <<-EOF
    exec dbus-run-session -- bash liveiso_path_scripts_root/user_specific.sh
EOF

# dconf write /org/cinnamon/desktop/interface/scaling-factor 1
error: Error spawning command line “dbus-launch --autolaunch=dafd9a61376b4676aa8b190bc1ed4b43 --binary-syntax --close-stderr”: Child process exited with code 1
root@alex:/# echo $?
1
root@alex:/# gsettings set org.cinnamon.desktop.interface scaling-factor 1

(process:242481): dconf-WARNING **: 08:34:30.432: failed to commit changes to dconf: Error spawning command line “dbus-launch --autolaunch=dafd9a61376b4676aa8b190bc1ed4b43 --binary-syntax --close-stderr”: Child process exited with code 1
root@alex:/# echo $?
0


[3]

# after custom binding is changed, noted that `gsettings get org.cinnamon.desktop.keybindings custom-list` output reverses from cusmomMAX to dummy and back, so in the script added that after each key assignments. It worked with only one reverse after all assignments in LM 20.2, but resluted in some keys not working in LM 21. With reverse after each key seems working in LM 21.
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__' ]"
# or dconf write /org/cinnamon/desktop/keybindings/custom-list "['__dummy__']"

# ----- previous code for custom-keybindings START ----- #
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/name "'Display rotate normal'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/binding "['<Super><Alt>Up']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/command "'display_rotate_normal.sh'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom0', '__dummy__']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/name "'Display rotate left'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/binding "['<Super><Alt>Left']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/command "'display_rotate_left.sh'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__', 'custom0', 'custom1']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/name "'Display rotate right'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/binding "['<Super><Alt>Right']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/command "'display_rotate_right.sh'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom2' ,'custom1', 'custom0', '__dummy__']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/name "'Display rotate upsidedown'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/binding "['<Super><Alt>Down']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom3/command "'display_rotate_inverted.sh'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__', 'custom0', 'custom1', 'custom2', 'custom3']"

# set key to up volume above 100% by increasing voltage 2x (+6dB doubles voltage according to wiki page)
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom4/name "'Volume Up'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom4/binding "['<Alt>AudioRaiseVolume']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom4/command "'pactl set-sink-volume @DEFAULT_SINK@ +6dB'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom4', 'custom3', 'custom2' ,'custom1', 'custom0', '__dummy__']"

# set key to lower volume by decreasing voltage 2x (-6dB halves voltage according to wiki page)
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom5/name "'Volume Down'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom5/binding "['<Alt>AudioLowerVolume']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom5/command "'pactl set-sink-volume @DEFAULT_SINK@ -6dB'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__', 'custom0', 'custom1', 'custom2', 'custom3', 'custom4', 'custom5']"

# fix TrackPoint issue om carbon X1 gen 6
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom6/name "'TrackPoint X1G6 fix'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom6/binding "['<Super><Alt>t']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom6/command "'/lib/systemd/system-sleep/trackpoint_reset key'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom6', 'custom5', 'custom4', 'custom3', 'custom2' ,'custom1', 'custom0', '__dummy__']"

# set custom screen scale
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom7/name "'Screen scale'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom7/binding "['<Super><Alt>s']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom7/command "'/lib/systemd/system-sleep/scaling_factor key'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__' , 'custom0', 'custom1', 'custom2', 'custom3', 'custom4', 'custom5', 'custom6', 'custom7']"

# screen lock binding, TODO check if xscreensaver deamon is started when ISO is booted with its debs installed
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom8/name "'Screen lock'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom8/binding "['<Super><Alt>x']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom8/command "'sh -c \'xscreensaver-command -lock || ( ( xscreensaver & ) && sleep 1 && xscreensaver-command -lock )\''"
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom8', 'custom7', 'custom6', 'custom5', 'custom4', 'custom3', 'custom2' ,'custom1', 'custom0', '__dummy__']"

# set custom monitor brightness adjustments
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom9/name "'Brightness up'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom9/binding "['<Alt>MonBrightnessUp']" # "['MonBrightnessUp']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom9/command "'night +1'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__' , 'custom0', 'custom1', 'custom2', 'custom3', 'custom4', 'custom5', 'custom6', 'custom7', 'custom8' ,'custom9']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom10/name "'Brightness down'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom10/binding "['<Alt>MonBrightnessDown']" # "['MonBrightnessDown']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom10/command "'night -1'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom10', 'custom9', 'custom8', 'custom7', 'custom6', 'custom5', 'custom4', 'custom3', 'custom2' ,'custom1', 'custom0', '__dummy__']"

# to replace opening Linux Mint web page on F1 press
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom11/name "'Help'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom11/binding "['F1']"
# dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom11/command "'notify-send \'NoNo help in GUI available, some info via man pages\''"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom11/command "'yelp'" # GUI help app (not included in the distro: to be istalled)
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__' , 'custom0', 'custom1', 'custom2', 'custom3', 'custom4', 'custom5', 'custom6', 'custom7', 'custom8' ,'custom9', 'custom10' ,'custom11']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom12/name "'Air fan(s) off'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom12/binding "['<Super><Alt>z']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom12/command "'stopfan'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom12', 'custom11', 'custom10', 'custom9', 'custom8', 'custom7', 'custom6', 'custom5', 'custom4', 'custom3', 'custom2' ,'custom1', 'custom0', '__dummy__']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom13/name "'Up text scaling 1.1 times'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom13/binding "['<Primary><Shift><Alt>x']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom13/command '"sh -c '\''f=$(gsettings get org.cinnamon.desktop.interface text-scaling-factor);fnew=$(printf \"print(${f}*1.1)\" | python); gsettings set org.cinnamon.desktop.interface text-scaling-factor ${fnew}'\'\"

gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__' , 'custom0', 'custom1', 'custom2', 'custom3', 'custom4', 'custom5', 'custom6', 'custom7', 'custom8' ,'custom9', 'custom10' ,'custom11', 'custom12', 'custom13']"

dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom14/name "'Up text scaling 0.9 times'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom14/binding "['<Primary><Shift><Alt>z']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom14/command '"sh -c '\''f=$(gsettings get org.cinnamon.desktop.interface text-scaling-factor);fnew=$(printf \"print(${f}*0.9)\" | python); gsettings set org.cinnamon.desktop.interface text-scaling-factor ${fnew}'\'\"

gsettings set org.cinnamon.desktop.keybindings custom-list "['custom14', 'custom13', 'custom12', 'custom11', 'custom10', 'custom9', 'custom8', 'custom7', 'custom6', 'custom5', 'custom4', 'custom3', 'custom2' ,'custom1', 'custom0', '__dummy__']"

# reversed order one more time in attempt to correct for <Alt>Audio LowerVolume and higher not working on one laptop on LM 21.2 TODO: test if the issue is solved
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__' , 'custom0', 'custom1', 'custom2', 'custom3', 'custom4', 'custom5', 'custom6', 'custom7', 'custom8' ,'custom9', 'custom10' ,'custom11', 'custom12', 'custom13', 'custom14']"
# ----- previous code END ----- #
