scripts use sudo
result is described by script names, plus
- run as usual user with sudo, not root
- it is supposed that script after_install.sh is run right after new system install (it runs individual setup scripts)

???
- link is made in home to ramdisk
- for keyboard shortcut, to make change permanent and to activate it, you need to edit created keyboard shortcut via GUI changing keyboard binding 

TODO
use org.cinnamon.* soemthing to store info, e.g. paths
maybe understand how trap is working in bash scripts, why some errors are caught, some are not

TODO
script_path=$0 # gives full (?"or relative path"? where have I read that?, nicely gives alsolute path, might be some issues with symbolic links), 
# not only file name

TODO
replace in scripts 
[ $1 = "--help" -o $1 = "-h" ]
with
[ $1 = "--help" -o $1 = "-h"  -o $1 = "?" ]

script(s) to copy Cinnamon 
- launcher,
- applets, 
- theame, 
- shortcuts,??? keyboard binings ???
+ - zooming enabled with "cursor pusher contects around", keys to zoom are win+alt+(+/-) and are Ok IMO now,
+ - horizontal schrolling enabled,
+ - display Hi-DPI scale enable,
(+/-) - screensaver start delay, delay before lock
+ - russian keyboard layout, switching by ctrl-space (no such option in GUI btw) - looks non-present do not work, e.g. tried 'grp\tgrp:ctrl_space_toggle'
- etc.
- power (maybe Cinnamon): delay(s) (on battery and on AC) before screen blacking
+ - show trash on desktop
+ - keyboard bindings for screen rotation

+ - nemo: columns: permissions, owner

- copy Firefox profile vs USB stick
- firefox ammend scripts for several ids of installs instances in profiles.ini

- sound volume up more - config keys to pactl set-sink-volume 1 +50% and the like
default buttons increase / reduce volume 5%, so may have only one extra for +50%
on screen though is 100% when buttons pressed if >100%, use pactl list sinks to see actual
maybe possible to amend those on-screen "notifications" of sound vodume 

+ - gnome terminal change zoom-in key to ctrl+=

- increase font used for boot

- script to print packages discriptions from deb files for all stored.

(+/-) - set system to shutdown if battery less than 10% (via upower?)

- tlp_config_battery.sh make to work when two batteries are present

- gsettings for networkmanager, [1]

collect errors during scrips runs and write to some install log


[1]

Usage:
  gsettings --version
  gsettings [--schemadir SCHEMADIR] COMMAND [ARGS…]


~$ gsettings list-keys org.gnome.nm-applet
show-applet
disable-disconnected-notifications
disable-wifi-create
suppress-wireless-networks-available
disable-vpn-notifications
disable-connected-notifications
stamp
~$ gsettings list-recursively org.gnome.nm-applet
org.gnome.nm-applet show-applet true
org.gnome.nm-applet disable-disconnected-notifications true
org.gnome.nm-applet disable-wifi-create false
org.gnome.nm-applet suppress-wireless-networks-available false
org.gnome.nm-applet disable-vpn-notifications false
org.gnome.nm-applet disable-connected-notifications true
org.gnome.nm-applet stamp 0
~$ man nmcli

/org/cinnamon/desktop/interface/scaling-factor

org.cinnamon.desktop.default-applications.terminal exec-arg '--'
org.cinnamon.desktop.default-applications.terminal exec 'gnome-terminal'

gsettings set x.dm.slick-greeter clock-format '%H:%M'

gsettings set org.cinnamon.control-center.display show-fractional-scaling-controls true
gsettings set org.cinnamon.desktop.interface scaling-factor 2
gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.0

gsettings set org.cinnamon.desktop.a11y.applications screen-magnifier-enabled true
gsettings set org.cinnamon.desktop.a11y.magnifier mouse-tracking push

gsettings set org.gnome.libgnomekbd.keyboard layouts "['us', 'ru']"
# gsettings set org.gnome.libgnomekbd.keyboard options "['grp\tgrp:win_space_toggle', 'terminate\tterminate:ctrl_alt_bksp', 'grp\tgrp:lalt_lshift_toggle']"
gsettings set org.gnome.libgnomekbd.keyboard options "['grp\tgrp:win_space_toggle', 'terminate\tterminate:ctrl_alt_bksp']"

gsettings set org.cinnamon.settings-daemon.peripherals.touchpad horizontal-scrolling true

gsettings set org.nemo.desktop visible-trash-icon true

gsettings set org.nemo.list-view default-visible-columns "['name', 'size', 'type', 'date_modified', 'owner', 'permissions']"
gsettings set org.nemo.list-view default-column-order "['name', 'size', 'type', 'date_modified', 'date_created_with_time', 'date_accessed', 'date_created', 'detailed_type', 'group', 'where', 'mime_type', 'date_modified_with_time', 'octal_permissions', 'owner', 'permissions']"

# [2]
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/zoom-in/ zoom-in "<Ctrl>equal"

# [1]
gsettings set  org.cinnamon.desktop.keybindings custom-list "['custom0', 'custom1', '__dummy__']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/name "'Display rotate left'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/binding "['<Alt>Left']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom0/command "'xrandr --output $(xrandr -q|grep -v disconnected|grep connected|awk '{print $1}') --rotate left'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/name "'Display rotate right'"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/binding "['<Alt>Right']"
dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom1/command "'xrandr --output $(xrandr -q|grep -v disconnected|grep connected|awk '{print $1}') --rotate right'"


gsettings set org.cinnamon.desktop.keybindings.custom-keybindings.custom1 name "Display rotate right"
/org/cinnamon/desktop/keybindings/custom-keybindings/custom1/name

org.cinnamon.desktop.screensaver lock-delay 600 # seconds
??? could not find delay before starting the screensaver

??? vs UPower.conf action 10 ???
org.gnome.settings-daemon.plugins.power
/org/gnome/settings-daemon/plugins/power/percentage-action 2

?? even when % is shown, another setting?
/org/gnome/desktop/interface/show-battery-percentage
false

/org/gnome/desktop/session/idle-delay

[2] https://askubuntu.com/questions/290159/how-can-i-use-gsettings-to-configure-settings-with-relocatable-schemas

[1]
https://unix.stackexchange.com/questions/596308/custom-keybindings-for-linux-mint-20-via-gsettings
below does not work, use dconf write
gsettings set org.cinnamon.desktop.keybindings.custom-keybindings.custom1 binding "['<Alt>Left']"
/org/cinnamon/desktop/keybindings/custom-keybindings/custom1/command "xrandr --output $(xrandr -q|grep -v disconnected|grep connected|awk '{print $1}') --rotate left"
gsettings set org.cinnamon.desktop.keybindings.custom-keybindings.custom0 name "Display rotate left"


