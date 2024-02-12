#!/bin/sh

# start xscreensaver before suspend to prevent last screen to be seen after resume
# running as user needed because seems `xscreensaver` needs .Xauthority to run screensaver
# using --suspend and then --deactivate instead of --lock as --lock results in blinking on display of the underlining image immediately after xscreensaver already activated and started drawing (and that resulted in sometimes blinking of the image after resume); --deactivate added to give user after resume a clue that xscreensaver is running, not blank display
sudo --user=mint sh -c '
if [ -z "$(xscreensaver-command --time | grep locked)" ]; then
    xscreensaver-command --suspend
    # xscreensaver-command --deactivate # commented out to check if removal will fix freezing of some laptops when lid is closed
else
    echo -e "\n Already locked"
    return 0; fi

if [ -n "$(xscreensaver-command --time | grep locked)" ]; then
    return 0
else
    return 1
fi'
