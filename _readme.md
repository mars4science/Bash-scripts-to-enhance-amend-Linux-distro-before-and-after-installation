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
- theame, 
- shortcuts, 
- zooming enabled with "cursor pusher contects around", keys to zoom are win+alt+(+/-) and are Ok IMO now,
- horizontal schrolling enabled,
- display Hi-DPI scale enable,
- screensaver start delay, delay before lock
- russian keyboard layout, switching by ctrl-space (no such option in GUI btw)
- etc.
- power (maybe Cinnamon): delay(s) (on battery and on AC) before screen blacking
- show trash on desktop

- nemo: columns: permissions, owner

- copy Firefox profile vs USB stick

- sound volume up more - config keys to pactl set-sink-volume 1 +50% and the like
default buttons increase / reduce volume 5%, so may have only one extra for +50%
on screen though is 100% when buttons pressed if >100%, use pactl list sinks to see actual
maybe possible to amend those on-screen "notifications" of sound vodume 

- nemo add owner and permissions to visible columns

- gnome terminal change zoom-in key to ctrl+=

- increase font used for boot

- script to print packages discriptions from deb files for all stored.

- set system to shutdown if battery less than 10% (via upower?)

- tlp_config_battery.sh make to work when two batteries are present



collect errors during scrips runs and write to some install log

