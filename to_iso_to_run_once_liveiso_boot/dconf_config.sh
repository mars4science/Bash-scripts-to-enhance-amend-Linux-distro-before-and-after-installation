#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# dbus-run-session needs to be used to run the script (to write to dconf database) before user login, for liveUSB the script is run from systemd_to_run_as_user.sh [1]

&>/dev/null dconf write /org/cinnamon/desktop/interface/scaling-factor 1
if [ $? -ne 0 ]; then
    1>&2 echo "-!- Per code and knowledge of the deleloper at time of this script was written,"
    1>&2 echo "-!- there is am indication that attempts to change dconf database here woould fail; aborting dconf_config"
    exit 1
fi

# ========= cinnamon / desktop / GUI settings ============
gsettings set org.cinnamon.control-center.display show-fractional-scaling-controls true
dpm=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4/$(NF-1)}') # dots per millimeter, rounded as bash test works with integers only
# at least gave "integer expression expected" for [ 3.4 -eq 45 ] 
dpi=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4/$(NF-1)*25.4}') # dots per inch, rounded
horizontal_relosution=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4}')

# does not seem to work in LM 21; GUI scaling controls work
if [ $dpm -ge 8 ] && [ $horizontal_relosution -ge 2000 ];then # maybe will be run on small displays, not change default scaling in such case
    gsettings set org.cinnamon.desktop.interface scaling-factor 2
    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.0
fi
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
gsettings set org.gnome.gnome-system-monitor update-interval 1000 # Time in milliseconds between updates of the process view
gsettings set org.gnome.gnome-system-monitor graph-update-interval 1000
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

gsettings set org.cinnamon.desktop.screensaver lock-delay 600 # seconds, ??? start delay not found via dconf Editor
gsettings set org.cinnamon.settings-daemon.plugins.power lock-on-suspend false # in GUI it is in screensaver settings window, diaable as reported workaround for reported bug of scale reset after suspend on Linux Mint 21 (bundled screensaver does not lock screen when booted as liveUSB, xscreensaver does and has many programs/themes)
gsettings set org.cinnamon.desktop.screensaver show-album-art false # to remote sometimes displyed youtube video picture from the screen
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 900 # in seconds
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800 # in seconds
gsettings set org.cinnamon.settings-daemon.plugins.power idle-dim-time 300 # in seconds, dim screen after becoming idle; timeout
gsettings set org.cinnamon.settings-daemon.plugins.power idle-brightness 10 # in %

# See [1] of _readme.md ([1] no longer there, what was it?), also for some reason command (for binding) that have $(xrandr do not work, only specific with e.g. eDP-1,
# therefore changed script code to make shell files and bind to them - it resulted in being able to use keys to rotate system's display
echo 'xrandr --output $(xrandr -q|grep -v disconnected|grep connected|awk '\''{print $1}'\'') --rotate normal' | sudo tee $(get_install_path.sh)/display_rotate_normal.sh
echo 'xrandr --output $(xrandr -q|grep -v disconnected|grep connected|awk '\''{print $1}'\'') --rotate left' | sudo tee $(get_install_path.sh)/display_rotate_left.sh
echo 'xrandr --output $(xrandr -q|grep -v disconnected|grep connected|awk '\''{print $1}'\'') --rotate right' | sudo tee $(get_install_path.sh)/display_rotate_right.sh
echo 'xrandr --output $(xrandr -q|grep -v disconnected|grep connected|awk '\''{print $1}'\'') --rotate inverted' | sudo tee $(get_install_path.sh)/display_rotate_inverted.sh
sudo chmod a+rx $(get_install_path.sh)/display_rotate_normal.sh $(get_install_path.sh)/display_rotate_left.sh $(get_install_path.sh)/display_rotate_right.sh $(get_install_path.sh)/display_rotate_inverted.sh

##### beginning of keyboard bindings #####

# after custom binding is changed, noted that `gsettings get org.cinnamon.desktop.keybindings custom-list` output reverses from cusmomMAX to dummy and back, so in the script added that after each key assignments. It worked with only one reverse after all assignments in LM 20.2, but resluted in some keys not working in LM 21. With reverse after each key seems working in LM 21.
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__' ]"
# or dconf write /org/cinnamon/desktop/keybindings/custom-list "['__dummy__']"

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
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom8/binding "['<Super><Alt>z']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom8/command "'sh -c \'xscreensaver-command -lock || ( ( xscreensaver & ) && sleep 1 && xscreensaver-command -lock )\''"
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom8', 'custom7', 'custom6', 'custom5', 'custom4', 'custom3', 'custom2' ,'custom1', 'custom0', '__dummy__']"

# set key to up volume above 100% by increasing voltage 2x (+6dB doubles voltage according to wiki page)
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom4/name "'Volume Up'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom4/binding "['<Alt>AudioRaiseVolume']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom4/command "'pactl set-sink-volume @DEFAULT_SINK@ +6dB'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom4', 'custom3', 'custom2' ,'custom1', 'custom0', '__dummy__']"

# set key to up volume above 100% by increasing voltage 2x (+6dB doubles voltage according to wiki page)
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom5/name "'Volume Down'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom5/binding "['<Alt>AudioLowerVolume']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom5/command "'pactl set-sink-volume @DEFAULT_SINK@ -6dB'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['__dummy__', 'custom0', 'custom1', 'custom2', 'custom3', 'custom4', 'custom5']"

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
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom12/binding "['<Super><Alt>z']" # "['MonBrightnessDown']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom12/command "'stopfan'"
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom12', 'custom11', 'custom10', 'custom9', 'custom8', 'custom7', 'custom6', 'custom5', 'custom4', 'custom3', 'custom2' ,'custom1', 'custom0', '__dummy__']"

##### end of keyboard bindings #####


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

gsettings set ca.desrt.dconf-editor.Settings show-warning false # If “true”, Dconf Editor opens a popup when launched reminding the user to be careful.
gsettings set org.gnome.nm-applet disable-disconnected-notifications true # Set this to true to disable notifications when disconnecting from a network.

desktop_background=liveiso_path_settings_root/background.jpg
if [ ! -e "$desktop_background" ] ; then desktop_background=/usr/share/backgrounds/linuxmint-ulyssa/echerkasski_countryside.jpg ; fi
gsettings set org.cinnamon.desktop.background picture-uri 'file://'"$desktop_background"

# UPDATE: setting not helping for some reason
gsettings set org.mate.applications-browser exec 'mozilla' # Default browser for URLs (to try to cancel firefox prompt to make it default at the first run)

# change theme for Cinnamon
gsettings set org.cinnamon.desktop.interface gtk-theme 'Mint-Y-Dark'
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



