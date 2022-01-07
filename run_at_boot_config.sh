#!/bin/bash
boot_script_path=/boot/custom_init.sh

# actually I have not thought where $0 is Ok and where realpath processing might add value
script_path="$(realpath "$0")"
if [ ! -d /var_on_disk ]; then 
    sudo mv /var /var_on_disk
    sudo mkdir /var
fi
if [ ! -d /tmp_on_disk ]; then 
    sudo mv /tmp /tmp_on_disk
    sudo mkdir /tmp
fi
if [ ! -d /tmp_on_disk ]; then sudo mv /tmp /tmp_on_disk; fi

sudo sed -i -E -- 's|GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"|GRUB_CMDLINE_LINUX_DEFAULT="init='$boot_script_path'"|' /etc/default/grub
sudo update-grub

sudo touch $boot_script_path
sudo chmod a+rx $boot_script_path
start_tag='start''_TAG' # extra '' added to make grep skip this line
start_line=$(($(cat $script_path | grep -n $start_tag | sed -E 's/([0-9]{1,}).*/\1/')-1))
exec tail -n +$start_line $script_path | 1>/dev/null sudo tee $boot_script_path
exit

#!/bin/bash
# start_TAG from line number substruct 1 to get starting line
# for tmpfs /var 
# to be added to grub menu entry(-ies) at the end of linux line in the form of init=boot_script_path

# https://www.urbanautomaton.com/blog/2014/09/09/redirecting-bash-script-output-to-syslog/
# exec 1> >(logger -s -t $(basename $script_path)) 2>&1
# above seems not to work, hypothesis is that logger job has not started at time of script run

echo executing $script_path
# exec tail -n 10 $script_path
echo custom init start
echo next to make /var, /tmp and add soft links to /var 
mount tmpfs -t tmpfs /var -o rw,size=10%
mount tmpfs -t tmpfs /tmp -o rw,size=5%
# make new folders on first boot
if [ ! -d /var/spool ];then mkdir /var/spool;fi
if [ ! -d /var/cache ];then mkdir /var/cache;fi
ln -s /var_on_disk/lib /var/lib
ln -s /var_on_disk/spool/cron /var/spool/cron
ln -s /var_on_disk/cache/man /var/cache/man
ln -s /run/lock /var/lock
ln -s /run /var/run
echo custom init finish, next call /sbin/init
exec /sbin/init
# TODO add functionality to write the above commands to the logs

# TODO add stopfan to systemd start-up where acpi already works (AFAIK this is the way to disable fan noise during startup, maybe thinkfan would take care of it if installed)
