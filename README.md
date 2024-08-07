﻿### Most of scripts written to amend installation or liveUSB iso file of linux distros. Tested on Linux Mint 21 and some Thinkpad laptops.

As of 2022/12/8 it is a small project, no formal QA. [testing] branch contains code that was run and no unexpected errors were noted, [main] means code was used more extensively, [devel] is for development in progress.

##### Disclaimer: some scripts produce modified ISO files which might no longer be considered original distros and might have no legal rights to be called by original names and distributed with original labels and other content. Only personal use for testing is implied.

- Scripts are expected to be run from path that does not contain spaces and special characters (not all variables are quoted).
- Some parts are specific to Linux Mint Cinnamon distribution (LM) and to ThinkPad laptops, scripts were tested on LM versions 20.2 and 21, ThinkPad Carbon X1 gen 6.
- Creating ISO files larger than 4Gb needs `mksquashfs` supporting `-no-strip` option, LM 21 has it.
- It's been noted `unmkinitramfs` somehow does not work correcty if scripts are run on a system based on distro different from the one of original ISO file (noted for LM 21 / 20), it affects changing initramfs (functionality can be turned on/off via change_initramfs control variable).

##### Copyright (c) 2009-2023, Alex Martian. All rights reserved.

##### The rights to the bash scripting code contained in these files and/or this git repository are granted under GNU GPL 3.0 license and GNU GPL 2.0 license.
##### Text of the licenses see in files LICENSE-* in this repo and/or https://www.gnu.org/licenses/gpl-3.0.en.html, https://www.gnu.org/licenses/gpl-2.0.en.html

#### _make_custom_liveusb.sh - to amend liveUSB iso (including splitting squashfs into two files if its amended size exceeds 4Gb)
- makes changes to initial boot environment (grub, isolinux), then
- calls via chroot `after_original_distro_install.sh`, that in turn run many other scripts from the repo (repo contains some scripts which are not called, and also some that are are IMO also useful as standalone)

_make_custom_liveusb.sh at the start have code to set several variables:

- distro_label - name_for_ISO_file and label of disk when mounted
- software_path_root - full path where data to add are located
- original_iso - full path to ISO file to amend
- work_path - full path with sufficient free space, end result (modified ISO file) is programmed to be left there after temporary files are deleted
- change_boot_menu - to set to "true" to edit boot menu (which adds options e.g. boot to ram, change id of live user, add rights for virt manager usage, replace splash/menu background image)
    - Note: above are variables to set to run example 1 of script usage (to only add some software with `apt-install` of debs), see examples at the end of README
- change_initramfs - to set to "true" to allow changes to initramfs (early boot environment), now code does changing of user name (inc. full name) and mounting /cow (includes upper file system for overlay which mounted over root when fully booted) in /casper to be able to see changes made to filesystem while running and allow easier amending of those changes
- locales - array of locales (languages/keyboard layouts) to add, first one is for interface language
- user_name - to replace user name in `run_at_boot_liveusb.sh`
- path_to_software_in_chroot - full path were data to be added is mounted during install (TODO - remove folder after install)
- liveiso_path_scripts_in_chroot - full path for scripts be copied to that are to run during boot via `systemd_to_run_as_user.sh`)
- liveiso_path_settings_in_chroot - full path for files to be copied to for copying to user folder during boot
- work_path_in_chroot - path to create temp files by scripts run in chroot


$work_path should have sufficient free space, now around several Gb, if fails due to space, someone can increase space and restart, it asks to delete previous temporary files when started (if finds any)

#### This script (+ scripts it is written to call) expects to find in path set by $software_path_root for parts of it functionality:

- `debs` - folders with debs, one folder for one application to install (via `install_debs.sh`, which in turn uses `apt_sources_replace.sh`, `apt_sources_restore.sh` and `apt_get.sh`)
- `debian_archives` - folder as proper debian archive, one containing folders with debs and `Packages` files (see `man apt-get`, `man dpkg`). `Packages` files may be created with `apt_sources_replace.sh`, which creates them in Dir::Etc folder (usually `/etc/apt`), also used by `install_debs.sh`. For download of deb files `download_debs.sh` may be used.
- `settings` - transmission folder as in user home, .xscreensaver as in user home, background.jpg to set as background
- `bin` - executables to add to path hardcoded in `get_install_path.sh` (now it is /usr/local/bin), including `night` - logarithmic control of brightness (linked to be called via custom keyboard binding), `stopfan` - stop fan of thinkpads (both see my other repo), youtube-dlp, yt-dlp
- `bin/appimages` - appimages to be added to path hardcoded in `get_install_path.sh`
- `bin/desktops` - desktop files used to display items in Cinnamon menu to be added
- `bin/icons` - icons for desktop files to be added
- `bin/the_rest` - contains executables to add to path hardcoded in `get_install_path.sh`
- `color-profiles` - contains specific profile to fix IMO incorrect color of a specific ThinkPad model (used by `set_color_profile.sh`)
- `/cinnamon/applets/`[to_add|to_add_and_activate] - applets to be added (via `cinnamon_add_software.sh`), also adding some to panel (activate) and amending settings of some (via `cinnamon_config.sh`)
- `wine-gecko`,
- `wine-mono` - folders with downloaded archives that are put on ISO by `install_wine-gecko.sh`, `install_wine-mono.sh`, on websites of those were found relatioships between vesions of wine and their in tables, in mentined scripts several matches for recent versions are coded.
- `*-browser-*` files - most recent selected and added (tar or zip archives of web browsers expected, used by `w_browser.sh`)
- `firefox-*.tar.bz2` files - most recent selected and added
- `files.py`, `files_functions.py` - scripts to add from my other repo (used for removing duplicates, sync, and some other tasks with files) to path hardcoded in `get_install_path.sh`
- `man_pages_edits.txt` - list of changes to the system reference manual pages
- `apt_dpkg_state` with dpkg_orig_status (dpkg status file) and sources.list and sources.list.d (apt sources) - used by `apt_get.sh` to install files in debs folder mentioned above (expected debs were downloaded with those files via `apt_get.sh` earlier) - TODO: think about getting them from original ISO

#### List of changes programmed to be made by _make_custom_liveusb.sh:

- several additional entries to boot menu of liveISO (text mode, toram, verbose)
- uuid of mint user changed to 1000 to make same as first user after installation (for ease of access to files owned by 1000 id user)
- add locales (languages/keyboard layouts), set interface language 
- add ramdisk location (tmpfs system), sets root and mint users cache to tmpfs
- add zramdisk location
- add zram device for swap (swap not activated on boot, to activate swap command: `swap on --all`)
- added Cinnamon applets (memory utilization and CPU temperature)
- install packages downloaded in advance and put in $software_path_root/debs
- add hotkeys (bindings) to rotate "main" screen, volume up/down 25% (6dB), logarithm based screen brightness up/down via `night` application, start screensaver
- change thresholds of remaining battery % for shutdown (via upower)
- switching layouts by ctrl-space (no such option in GUI btw)
- add columns to system monitor: resident memory, command line
- makes some of of the system reference manual pages more easily found by `apropos` | `man -k` and for understanding (via `man_pages_edits.sh` script, processing list of changes from `man_pages_edits.txt`, for format and location of txt file see comments in the script code)
- Cinnamon tweaks:
    - zooming enabled with "cursor pushes contents around", keys to zoom are super(win)+alt+(+/-)
    - horizontal scrolling enabled
    - display Hi-DPI scale enable
    - show trash on desktop
    - setting to do not utomatically open a folder for automounted media (opened in file manager by default in Linux Mint 20.2)
    - setting to neither prompt nor autorun/autostart programs when a medium is inserted
    - setting desktop background
- Nemo tweaks:
    - add columns: permissions, owner
    - add bookmarks for ramdisk (Ramdisk), zramdisk (Compressed RAM) - via `user_bookmarks_add.sh` / `user_bash_home_bookmarks_prompt.sh` (later also changes bash prompt)


Scripts added to /usr/local/bin:

- `apt_get` downloads and/or installs apt packages storing downloaded in $software_path_root/debs location, uses (temporary sets) dpkg_orig_status file from $software_path_root location (or another via command line parameter) as dpkg status
- `f_ree` delete cashes on disk, Firefox saved sites data, etc.
- `fox_profile_put`, `fox_profile_get` - save and retrieve current Firefox profile data to /media/$(id -un)/usb/
- `w_browser` extract and run additional web browser from ramdisk location
- `k_iwix` runs kiwix appimage with some variables set as a workaround to libGL error 
- `git_clone` clones specific git repo with mirror option then amends config to make cloned repo look as regular
- `git_compact` compacts repo with `git switch --orphan empty_long_name`
- `man_pages_search` Searches sources files of the system reference manual pages for containing all arguments as literal strings (case insensitive) in any order (aka --global-apropos but for multiple arguments as `man` application itself for some reason seems to have no such option)
- `apt_sources_replace`, `apt_sources_restore` - replace and restore apt sources and index files, e.g. for install from local debian archive
- `download_debs` - to download set of debian packages with default dependencies in one go to apt cache, based on list of packages in a file. One may try to use `apt_get cp` to copy from cache to current folder afterwardsy

Other minor tweaks, including:

- sets systemd task at boot target for transmission settings
- replaces Firefox (`firefox-replace.sh`) with downloaded (and w/out google search engine selection disabled in Mint) version; the script's code is written to process tar or zip archives with `firefox` executable to start Firefox located in root of archive or in single top folder of the archive (usually named "firefox")
- makes mpv default for video/audio file types, configures some mpv keys (`apps_config.sh`)
- workaround of problem of specific old color printer (`printer_color_as_gray.sh`)
- installs python scripts, i.e. `files.py` (program from my other repo), placed in software_path_root by `utils_misc_install.sh`
- disables swap (`disable_swap.sh`)
- notifies on low memory (`memory_notify_config.sh`)
- add functions to bash (added to `/etc/bash.bashrc` via `bash_functions_and_other_config.sh`)
    - `mntro`, `mntrw` to make mount read-only and read-write respectively, 
    - `e_ject` - eject usb storage
    - `git_pull` to pull (with fast-forward merge only) all tracked branches from "origin"
    - `git_merge` to merge (fast-forward only) current branch into all other local branches

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

#### _prepare.sh

- to (temporarily) amend `_make_custom_liveusb.sh` (variables mostly) and `bash_functions_and_other_config.sh`
- to make some changes to contents of $software_path_root about what applications (e.g. AppImage files) to install
- takes files from addditional directory (folder in root of $software_path_root, parameter in `_prepare.sh`) and adds to other locations within $software_path_root


### Examples

#### Example 1 (to only add some software done with `apt-install` of deb files)
- copy the following scripts to empty folder:
    - `after_original_distro_install.sh`
    - `apt_get.sh`
    - `install_debs.sh`
    - `apt_sources_replace.sh`
    - `apt_sources_restore.sh`
    - `_make_custom_liveusb.sh`
- set variables listed at the beginning of _make_custom_liveusb.sh, see more detailed descriptions in the beginning of README.
    - distro_label - "arbirary string with no special symbols, no spaces"
    - software_path_root - full path where folder "debs" with software packages to add is located. Separate subfolder for each package, set of deb files for each package (main package and its dependencies) can be downloaded via apt_get.sh script (which uses `apt-get install --download-only`)
    - original_iso - full path to ISO file to amend
    - work_path - full path with sufficient free space, end result (modified ISO file) is programmed to be left there after temporary files are deleted
    - change_boot_menu - set to "false"
- run `_make_custom_liveusb.sh`, ignore notifications that files cannot be read/found, for installation of deb files see section starting from "===== next in a few seconds going to install downloaded debian packages =====" and ending with "===== This line is after install code, next in a few seconds going to continue ====="
- upon completion of the script collect ISO file named in accordance with distro_label from work_path

#### TODO 

- DONE: fix `after_login_config.sh` where Nemo bookmarks set do not correspond to actual folders in $HOME in case of interface language change
- find out if notifications can be displayed on top of `mpv` in full-screen (now see ones made by `notify-send` don't) 
- at the end of install remove folder $path_to_software_in_chroot set in `_make_custom_liveusb.sh`  (path were data to be added is mounted during install)
- DONE: move copying of data from `_make_custom_liveusb.sh` to `after_original_distro_install.sh` - as of now decided not needed as this copying needed for liveISO modification only, for running system `after_original_distro_install.sh` have code to call the scripts and copy settings
- power (maybe Cinnamon): delay(s) (on battery and on AC) before screen blacking
- investigate why for liveUSB tlp config of wifi off during boot is not honored
- use org.cinnamon.* something to store info, e.g. paths
- maybe understand how trap is working in bash scripts, why some errors are caught, some are not
- collect errors during scrips runs and write to some install log
- gnome terminal change zoom-in key to ctrl+=
- increase font used for boot
- script to print packages dscriptions from deb files for all stored.
- `tlp_config_battery.sh` make to work when two batteries are present
- fix code to remove limitation of running from path that does not contain spaces and special characters (complete quoting of variables)
- DONE: change git_clone to set refs to be able to push/pull from a repo supplied as argument to the script
