#!/bin/bash
# thinkpad specific
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi

sudo cp --no-clobber "$software_path_root"/bin/stopfan $(get_install_path.sh)
# sudo chown root /usr/bin/stopfan
# will be owned by root after copy anyway
# +xs execute as owner (root)
# control works after restart, understanding how to enable w/out restart in progress (modules reload, etc.)
sudo chmod +xs $(get_install_path.sh)/stopfan

# check if fan control already enabled (e.g. custom liveUSB)
if [ -e /etc/modprobe.d/thinkpad_acpi.conf ]; then 
    cat /etc/modprobe.d/thinkpad_acpi.conf | grep "options thinkpad_acpi fan_control=1" > /dev/null
    if [ $? -eq 0 ]; then # return from grep is found then $? eq 0 true (Normally the exit status is 0 if a line is selected : man grep)
        # stopfan w/out parameters does something equivalent to the following line:
        # echo disable | sudo tee /proc/acpi/ibm/fan
        stopfan # disable fan
        exit
    fi
fi

# can be disabled after reboot only as have not found a way to reload module / to apply new config file
echo fan control is not enabled, restart might be needed after writing that option:
echo 'options thinkpad_acpi fan_control=1' | sudo tee -a /etc/modprobe.d/thinkpad_acpi.conf

