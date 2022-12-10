### Most of scripts written to amend installation or liveUSB iso file of linux distros. Tested on Linux Mint 21 and some Thinkpad laptops.

#### As of 2022/12/8 it is a small project, no formal QA. [testing] branch contains code that was run and mo unexpected errors were noted, ]main] means code was used more extensively, [devel] is for development in progress.

#### Disclaimer: some scripts produce modified ISO files which might no longer be considered original distros and might have no legal rights to be called by original names and distributed with original labels and other contents. Only personal use for testing is implied. 

##### Copyright (c) 2009-present, Alex Martianov. All rights reserved. 

##### The rights to the bash scripting code contained in these files and/or this git repository are granted under GNU GPL 3.0 license and GNU GPL 2.0 license.
##### Text of the licenses see in files LICENSE-* in this repo and/or https://www.gnu.org/licenses/gpl-3.0.en.html, https://www.gnu.org/licenses/gpl-2.0.en.html

#### _make_custom_liveusb.sh to amend liveUSB iso 
It calls many other scripts from the repo. 
(Some other scripts are not called, some that are are IMO also useful as standalone)

_make_custom_liveusb.sh at the start have code to set several variables:

- distro_label="name_for_ISO_file and label of disk when mounted"
- original_iso=/media/data/Software/distros/linuxmint-21-cinnamon-64bit.iso
- work_path=/media/ramdrive/custom_iso
- software_path_root=/media/usb/data

$work_path should have sufficient free space, now around several Gb, if fails due to space, someone can increase space and restart, it asks to delete previous temporary files when started (if finds any)

#### This script (+ scripts it is written to call) expects to find in path set by $software_path_root for parts of it functionality:

- debs - folders with debs, one folder for one application to install
- settings - transmission folder as in user home, .xscreensaver as in user home, background.jpg to set as background
- bin - executables to add to folder in PATH, including night - logarithmic control of brightness (linked to be called via custom keyboard binding) , stopfan - stop fan of thinkpads (both see my other repo) , youtube-dlp, yt-dlp
- bin/appimages - appimages to be added 
- bin/desktops (desktop files used to display items in Cinnamon menu to be added)
- bin/icons (icons for desktop files to be added)
- bin/the_rest (contains executables to add to folder in $PATH) folders 
- color-profiles - contains specific profile to fix IMO incorrect color of a specific ThinkPad model (used by set_color_profile.sh)
- cinnamon-applets - applets to be added, also for mem-monitor-text@datanom.net and temperature@fevimu there is code to amend their settings (code in  cinnamon_config.sh)
- wine-gecko,
- wine-mono - folders with downloaded archives that are put on ISO by install_wine-gecko.sh, install_wine-mono.sh, om websites of those were found relatioships between vesions of wine and their in tables, in mentined scripts several matches for recent versions are coded.
- tor-browser-linux64-*.tar.xz files - most recent selected and added
- firefox-*.tar.bz2 files - most recent selected and added
- files.py, files_functions.py - scripts to add from my other repo (used for removing duplicates, sync, and some other tasks with files)
- apt_dpkg_state with dpkg_orig_status (dpkg status file) and sources.list and sources.list.d (apt sources) - used by apt_get.sh to install files in debs folder mentioned above (expected debs were downloaded with those files via apt_get.sh earlier) - TODO: think about getting them from original ISO

#### List of changes programmed to be made by _make_custom_liveusb.sh:

- several additional entries to boot menu of liveISO (text mode, to ram, verbose)
- uuid of mint user changed to 1000 to make same as first user after installation (for ease of access to files owned by 1000 id user)
- add ramdrive location (tmpfs system), sets root and mint users cache to tmpfs 
- added Cinnamon applets (memory utilization and CPU temperature)
- install packages downloaded in advance and put in $software_path_root/debs
- add hotkeys (bindings) to rotate "main" screen, volume up 25%, logarithm based screen brightness up/down, start screensaver
- change thresholds of remaining battery % for shutdown (via upower)

- Cinnamon tweaks:
    - zooming enabled with "cursor pushes contents around", keys to zoom are win+alt+(+/-)
    - horizontal scrolling enabled
    - display Hi-DPI scale enable
    - show trash on desktop
    - keyboard bindings for screen rotation
    - Nemo: add columns: permissions, owner

Thinkpad specific: 

- screen brightness changed to change by log scale via standard keys (works on Thinkpads via written on C program)

Locale specific:

- russian keyboard layout, switching by ctrl-space (no such option in GUI btw)   looks non-present do not work, e.g. tried 'grp\tgrp:ctrl_space_toggle'

Scripts added to /usr/local/bin:

- apt_get downloads and/or installs apt packages storing downloaded in $software_path_root/debs location, uses (temporary sets) dpkg_orig_status file from $software_path_root location (or another via command line parameter) as dpkg status
- f_ree delete cashes on disk, Firefox saved sites data, etc.
- fox_profile_put, fox_profile_get - save and retrieve current Firefox profile data to /media/$(id -un)/usb/
- t_or extract and run TOR from ramdrive location
- k_iwix runs kiwix appimage with some variables set as a workaround to libGL error 
- git_clone clones specific repo
- git_compact compacts repo

Other minor tweaks, e.g.:

- sets systemd task at boot target for transmission settings
- replaces Firefox with newer (and w/out google search engine selection disabled in Mint) version
- makes mpv default for video file types, configures some mpv keys (mpv_config.sh)
- workaround of problem of specific old color printer (printer_color_as_gray.sh)
- installs python scripts, i.e. files.py (program from from other repo, if placed in software_path_root) (Utils_misc_install.sh)
- disables swap (disable_swap.sh)
- notifyes on low memory (memory_notify_config.sh, might not work)
- add mnt_ro mnt_rw functions to make mount read-only and rw respectively, e_ject - eject usb storage (bash_functions.sh)

##### Scripts to amend ISO are written to be run as ordinary user, they use sudo in themselves

#### after_original_distro_install.sh to amend system after installation.

#### Some others:

_make_usb_persistent.sh - standalone script to edit ISO file to change default boot parameters
r_sync.sh – not finalized try on using rsync to synchronize two folders both ways (see code and comments in the script how it works)


#### TODO 

- power (maybe Cinnamon): delay(s) (on battery and on AC) before screen blacking
- investigate why for liveUSB tlp config of wifi off during boot is not honored
- use org.cinnamon.* something to store info, e.g. paths
- maybe understand how trap is working in bash scripts, why some errors are caught, some are not
- collect errors during scrips runs and write to some install log
- gnome terminal change zoom-in key to ctrl+=
- increase font used for boot
- script to print packages dscriptions from deb files for all stored.
- tlp_config_battery.sh make to work when two batteries are present

