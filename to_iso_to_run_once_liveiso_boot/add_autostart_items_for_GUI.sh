#!/bin/bash

autostart_dir=/home/$(id -u -n)/.config/autostart
mkdir --parents $autostart_dir

# Note: 
# For `Exec` using '~' for home resulted in no expected results, so seems absolute paths needed

# ----- BOOKMARKS ----- #

# file created by GUI had Name[en_US] but no Name w/out locale, so in other system language interface boot it was not run
tee $autostart_dir/nemo.bookmarks.add.desktop << EOF
[Desktop Entry]
Name=bookmarks-add-to-nemo
Comment=No description
Type=Application
Exec=liveiso_path_scripts_root/user_bookmarks_add.sh
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
X-GNOME-Autostart-Delay=0
EOF


# ----- start xscreensaver daemon ----- #

# xscreensaver needs .Xauthority file, it could be started via systemd via `Type=forking` type and `ExecStart=sudo --user=mint sh -c 'xscreensaver -no-splash &'`; however also .Xauthority need to be created before that, so use for this case Cinnamon's autostart feature which is run after GUI started, so .Xauthority is there and user is current user (user is root for ExecStart in systemd services) 

tee $autostart_dir/xscreensaver.start.desktop << EOF
[Desktop Entry]
Name=xscreensaver-start
Comment=No description
Type=Application
Exec=sh -c 'xscreensaver -no-splash &'
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
X-GNOME-Autostart-Delay=0
EOF

# includes setting scaling of fonts in Cinnamon based on display's resolution and pixels density (and guesswork about overall monitor scaling factor as still have not found a way to read it by shell code)
tee $autostart_dir/gui.configure.desktop << EOF
[Desktop Entry]
Name=fonts.scaling.set
Comment=No description
Type=Application
Exec=liveiso_path_scripts_root/gui_configure.sh
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
X-GNOME-Autostart-Delay=0
EOF

# Seems to be no need to make desktop files executable in autostart, works w/out it but just in case:
chmod a+x $autostart_dir/*

