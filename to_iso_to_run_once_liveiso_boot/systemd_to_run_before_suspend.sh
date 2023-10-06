#!/bin/sh

# start xscreensaver before suspend to prevent last screen to be seen after resume
# running as user needed because seems `xscreensaver` needs .Xauthority to run screensaver
sudo --user=mint xscreensaver-command --lock
