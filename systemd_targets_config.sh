#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR


if [ ! -e "${liveiso_path_scripts_root}" ] ; then liveiso_path_scripts_root=/usr/share/amendedliveiso-scripts ; fi

add_service(){

    service_file_fully_qualified_name=/lib/systemd/system/$service_file_name

    if [ -e "$service_file_fully_qualified_name" ];then
        1>&2 echo "$service_file_fully_qualified_name exists, next is programmed to abort configuring systemd"
        exit 1
    fi

    # /dev/null not to output to terminal
    echo "$service_file_contents" | 1>/dev/null sudo tee "$service_file_fully_qualified_name"

    # "systemctl enable" created links, so comment out below line (Note: after editing out some of WantedBy "systemctl enable" did NOT delete links to deleted targets; "systemctl disable" deletes targets. Therefore seems one needs to firstly disable, secondly edit and thirdly enable to be safe)
    # sudo ln --symbolic "$service_file_fully_qualified_name" /etc/systemd/system/multi-user.target.wants/"$service_file_name"

    systemctl enable $service_file_name
}

# ----- systemd service to run a script to config user environment (AFAIK would be run before login) ----- #
# could not find info that dbus-daemon is started by systemd, so no dependencies (Requires=, After= : see man systemd.service) 

service_file_contents="[Unit]
Description=run a script to config user environment (AFAIK would be run before login)

[Service]
Type=oneshot
ExecStart=$liveiso_path_scripts_root/systemd_to_run_as_user.sh

[Install]
WantedBy=multi-user.target"

service_file_name=PreloginUserConfig.service
add_service

# ----- add zram (compressed ram drive) at boot ----- #
service_file_contents="[Unit]
Description=add zram (compressed ram drive) at boot (AFAIK would be run before login)

[Service]
Type=oneshot
ExecStart=$liveiso_path_scripts_root/add_zram.sh

[Install]
WantedBy=multi-user.target"

service_file_name=ZramAdd.service
add_service

# https://unix.stackexchange.com/questions/47695/how-to-write-startup-script-for-systemd/687324
