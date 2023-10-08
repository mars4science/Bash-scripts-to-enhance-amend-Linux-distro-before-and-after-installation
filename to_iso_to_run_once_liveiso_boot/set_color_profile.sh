#!/bin/bash
# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# TODO to check if color profile could be set for display not yet connected 
# run manually only for T480s with specific panel to set downloaded profile (that was programmed to be copied to /usr/share/color/icc/colord
# set profile for T480s, might set for other laptops because display might list as same device, but for several other ThinkPads checked device name was different as displayed by `colormgr get-devices`
device_for_color="/org/freedesktop/ColorManager/devices/xrandr_eDP_1_mint_1000"
profile_for_color="icc-f2e7fb65b32fcc4e864150b3134ba53e" # noted other path on other system but id remained 
colormgr device-add-profile "$device_for_color" "$profile_for_color"
colormgr device-make-profile-default "$device_for_color" "$profile_for_color"
