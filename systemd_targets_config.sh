#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# systemd service to run a script to config user environment (AFAIK would be run before login)
# could not find info that dbus-daemon is started by systemd, so no dependencies (Requires=, After= : see man systemd.service) 

service_file_contents="[Unit]
Description=run a script to config user environment (AFAIK would be run before login)

[Service]
Type=oneshot
ExecStart=/am/systemd_to_run_as_user.sh

[Install]
WantedBy=multi-user.target"

service_file_name=AmUserConfig.service
service_file_fully_qualified_name=/lib/systemd/system/$service_file_name

if [ -e "$service_file_fully_qualified_name" ];then 
    1>&2 echo "$service_file_fully_qualified_name exists, next is programmed to abort configuring systemd"
    exit 1
fi

# /dev/null not to output to terminal
echo "$service_file_contents" | 1>/dev/null sudo tee "$service_file_fully_qualified_name"
sudo ln --symbolic "$service_file_fully_qualified_name" /etc/systemd/system/multi-user.target.wants/service_file_name

systemctl enable $service_file_name

exit

https://unix.stackexchange.com/questions/47695/how-to-write-startup-script-for-systemd/687324
