#!/bin/sh

# start xscreensaver before suspend to prevent last screen to be seen after resume
# running as user needed because seems `xscreensaver` needs .Xauthority to run screensaver
sudo --user=mint xscreensaver-command --lock
sudo --user=mint xscreensaver-command --lock # in one setting noted running just one time have been resulting in last screen flashing after resume, maybe simple `sleep 1` consistently achieves same
