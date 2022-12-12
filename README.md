### Most of scripts written to amend installation or liveUSB iso file of linux distros. Tested on Linux Mint 21 and some Thinkpad laptops.

#### As of 2022/12/8 it is a small project, no formal QA. [testing] branch contains code that was run and no unexpected errors were noted, [main] means code was used more extensively, [devel] is for development in progress.

#### Disclaimer: some scripts produce modified ISO files which might no longer be considered original distros and might have no legal rights to be called by original names and distributed with original labels and other content. Only personal use for testing is implied. 

Scripts are expected to be run from path that does not contain spaces and special characters (not all variables are quoted).

Some parts are specific to Linux Mint Cinnamon distribution (LM) and to ThinkPad laptops, scripts were tested on LM versions 20.2 and 21, ThinkPad Carbon X1 gen 6.

##### Copyright (c) 2009-2022, Alex Martian. All rights reserved. 

##### The rights to the bash scripting code contained in these files and/or this git repository are granted under GNU GPL 3.0 license and GNU GPL 2.0 license.
##### Text of the licenses see in files LICENSE-* in this repo and/or https://www.gnu.org/licenses/gpl-3.0.en.html, https://www.gnu.org/licenses/gpl-2.0.en.html

#### _make_custom_liveusb.sh - to amend liveUSB iso
- makes changes to initial boot environment (grub, isolinux), then
- calls via chroot `after_original_distro_install.sh`, that in turn run many other scripts from the repo (repo contains some scripts which are not called, and also some that are are IMO also useful as standalone)

_make_custom_liveusb.sh at the start have code to set several variables:

- distro_label="name_for_ISO_file and label of disk when mounted"
- original_iso - full path to ISO file to amend
- work_path - full path with sufficient free space, end result (modified ISO file) is programmed to be left there after temporary files are deleted
- software_path_root - full path where data to add are located 
- user_name - to replace user name in `run_at_boot_liveusb.sh`
- path_to_software_in_chroot - full path were data to be added is mounted during install (TODO - remove folder after install)
- liveiso_path_scripts_in_chroot - full path for scripts be copied to that are to run during boot via `systemd_to_run_as_user.sh`)
- liveiso_path_settings_in_chroot - full path for files to be copied to for copying to user folder during boot

$work_path should have sufficient free space, now around several Gb, if fails due to space, someone can increase space and restart, it asks to delete previous temporary files when started (if finds any)

#### This script (+ scripts it is written to call) expects to find in path set by $software_path_root for parts of it functionality:

- debs - folders with debs, one folder for one application to install (via `apt_get.sh`)
- settings - transmission folder as in user home, .xscreensaver as in user home, background.jpg to set as background
- bin - executables to add to path hardcoded in `get_install_path.sh` (now it is /usr/local/bin), including night - logarithmic control of brightness (linked to be called via custom keyboard binding), stopfan - stop fan of thinkpads (both see my other repo), youtube-dlp, yt-dlp
- bin/appimages - appimages to be added to path hardcoded in `get_install_path.sh`
- bin/desktops - desktop files used to display items in Cinnamon menu to be added
- bin/icons - icons for desktop files to be added
- bin/the_rest - contains executables to add to path hardcoded in `get_install_path.sh`
- color-profiles - contains specific profile to fix IMO incorrect color of a specific ThinkPad model (used by `set_color_profile.sh`)
- cinnamon-applets - applets to be added (via `cinnamon_add_software.sh`), also for mem-monitor-text@datanom.net and temperature@fevimu there is code to amend their settings (code in  `cinnamon_config.sh`)
- wine-gecko,
- wine-mono - folders with downloaded archives that are put on ISO by `install_wine-gecko.sh`, `install_wine-mono.sh`, on websites of those were found relatioships between vesions of wine and their in tables, in mentined scripts several matches for recent versions are coded.
- tor-browser-linux64-*.tar.xz files - most recent selected and added
- firefox-*.tar.bz2 files - most recent selected and added
- files.py, files_functions.py - scripts to add from my other repo (used for removing duplicates, sync, and some other tasks with files) to path hardcoded in `get_install_path.sh`
- apt_dpkg_state with dpkg_orig_status (dpkg status file) and sources.list and sources.list.d (apt sources) - used by `apt_get.sh` to install files in debs folder mentioned above (expected debs were downloaded with those files via `apt_get.sh` earlier) - TODO: think about getting them from original ISO

#### List of changes programmed to be made by _make_custom_liveusb.sh:

- several additional entries to boot menu of liveISO (text mode, toram, verbose)
- uuid of mint user changed to 1000 to make same as first user after installation (for ease of access to files owned by 1000 id user)
- add ramdisk location (tmpfs system), sets root and mint users cache to tmpfs
- add zramdisk location
- add zram device for swap (swap not activated on boot, to activate swap command: `swap on --all`)
- added Cinnamon applets (memory utilization and CPU temperature)
- install packages downloaded in advance and put in $software_path_root/debs
- add hotkeys (bindings) to rotate "main" screen, volume up/down 25% (6dB), logarithm based screen brightness up/down via `night` application, start screensaver
- change thresholds of remaining battery % for shutdown (via upower)
- switching layouts by ctrl-space (no such option in GUI btw)
- add more columns to system monitor
- Cinnamon tweaks:
    - zooming enabled with "cursor pushes contents around", keys to zoom are super(win)+alt+(+/-)
    - horizontal scrolling enabled
    - display Hi-DPI scale enable
    - show trash on desktop
    - Nemo: add columns: permissions, owner
    - Nemo: setting to do not utomatically open a folder for automounted media
    - Nemo: setting to neither prompt nor autorun/autostart programs when a medium is inserted
    - setting desktop background

Scripts added to /usr/local/bin:

- `apt_get` downloads and/or installs apt packages storing downloaded in $software_path_root/debs location, uses (temporary sets) dpkg_orig_status file from $software_path_root location (or another via command line parameter) as dpkg status
- `f_ree` delete cashes on disk, Firefox saved sites data, etc.
- `fox_profile_put`, `fox_profile_get` - save and retrieve current Firefox profile data to /media/$(id -un)/usb/
- `t_or` extract and run TOR from ramdisk location
- `k_iwix` runs kiwix appimage with some variables set as a workaround to libGL error 
- `git_clone` clones specific git repo via `git clone mirror-- $1 ../.git` (all branches, see man page of git-clone for details on refs)
- `git_compact` compacts repo with `git switch --orphan empty_long_name`

Other minor tweaks, e.g.:

- sets systemd task at boot target for transmission settings
- replaces Firefox with downloaded (and w/out google search engine selection disabled in Mint) version
- makes mpv default for video/audio file types, configures some mpv keys (`mpv_config.sh`)
- workaround of problem of specific old color printer (`printer_color_as_gray.sh`)
- installs python scripts, i.e. `files.py` (program from my other repo), placed in software_path_root by `Utils_misc_install.sh`
- disables swap (`disable_swap.sh`)
- notifyes on low memory (`memory_notify_config.sh`, might not work)
- add mntro mntrw functions to make mount read-only and read-write respectively, e_ject - eject usb storage (added via `bash_functions.sh`)

##### Scripts to amend ISO are written to be run as ordinary user, they use sudo in themselves

#### after_original_distro_install.sh - to amend system after installation
- this script is called by `_make_custom_liveusb.sh` to make changes
- does (mosstly via calling other scripts) almost all work to amend filesystem.squashfs file of liveISO (GNU/Linux system loaded by initramfs - initial bootloader)
- does almost all data copying from the list of data to be copied (some is done in `_make_custom_liveusb.sh`) (TODO - move to `after_original_distro_install.sh` as idea is that it can do *all* changes to system after install)

#### Some other scripts:
- `apt_get.sh` - download and/or install from local storage deb packages substituting dpkg status and apt sources
- `_make_usb_persistent.sh` - standalone script to edit ISO file to change default boot parameters
- `_rename_based_on_meta.sh` - standalone script using ffmpeg
- `_r_sync.sh` – not finalized try on using rsync to synchronize two folders both ways (see code and comments in the script how it works)

#### TODO 

- at the end of install remove folder $path_to_software_in_chroot set in `_make_custom_liveusb.sh`  (path were data to be added is mounted during install)
- move copying of data from `_make_custom_liveusb.sh` to `after_original_distro_install.sh`
- power (maybe Cinnamon): delay(s) (on battery and on AC) before screen blacking
- investigate why for liveUSB tlp config of wifi off during boot is not honored
- use org.cinnamon.* something to store info, e.g. paths
- maybe understand how trap is working in bash scripts, why some errors are caught, some are not
- collect errors during scrips runs and write to some install log
- gnome terminal change zoom-in key to ctrl+=
- increase font used for boot
- script to print packages dscriptions from deb files for all stored.
- `tlp_config_battery.sh` make to work when two batteries are present
- fix code to remove limitation of running from path that does not contain spaces and special characters (complete quoting variables)
- change git_clone to set refs to be able to push/pull from a repo supplied as argument to the script
