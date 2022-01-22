#!/bin/bash

trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# decided to edit system wide 
# /etc/bash.bashrc instead of ~/.bashrc

# ~/.bashrc contains lines that overwrite PS1 from /etc/bash.bashrc, so editing ~/.bashrc to change user prompt is needed 
# if current user is root (e.g. chrooted duriong liveUSB creation), then ~ would exist, but not /home/$(id -u -n)
if [ -e /home/$(id -u -n)/.bashrc ]; then
    echo '' >> ~/.bashrc
    echo '# bash prompt, LM original and setting it' >> ~/.bashrc
    echo '# \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$' >> ~/.bashrc
    echo 'PS1='\''\[\033[01;34m\]\w\[\033[00m\]\$ '\''' >> ~/.bashrc
fi
echo '' | sudo tee --append /etc/bash.bashrc
echo 'PS1='\''\[\033[01;34m\]\w\[\033[00m\]\$ '\''' | sudo tee --append /etc/bash.bashrc
echo '' | sudo tee --append /etc/bash.bashrc

# https://unix.stackexchange.com/questions/35508/eject-usb-drives-eject-command/83587
# Not sure a function need to be exported each time of login, but count not find an asnwer to that in man bash and do not want to google now.
# Therefore to be on the safe side below (adding to user profile) is expected to be Ok (multiple re-export did not output any errors):

# simplier version
# echo 'e_ject() { 2>/dev/null eject $1;udisksctl power-off -b $1; }; export -f e_ject' >> /home/$(id -u -n)/.profile

# to use: e_ject name
# name is searched (grepped) in mount output of all mounts, expected to be present on one line only, but seems to work fine even if on multiple mounts e.g. for e_ject sdb with multiple partitions USB stick. On my system both eject and udisksctl work with partition (/dev/sdbx) parameter.
# 2>/dev/null is added due to eject outputing an error each time, but result seemed correct.
# Not sure a function need to be exported each time of login, but count not find an asnwer to that in man bash and do not want to google now. Therefore to be on the safe side below (adding to user profile) is expected to be Ok (multiple re-export did not output any errors):

# ADDED: sometimes produced error at time of power-off, hypothesis is that umounting took longer than exit from eject, so added a cycle
echo '' | sudo tee --append /etc/bash.bashrc
# echo 'e_ject() { dev=$(mount | grep --ignore-case $1 | awk --field-separator " " '\''{ FS = " " ; print $1 ; exit }'\'');2>/dev/null eject $dev;udisksctl power-off -b $dev; }; export -f e_ject' | sudo tee --append /etc/bash.bashrc
# awk separator is space by default
# for awk '' are needed cause $1 is awk notation, if "" than would be expanded by the shell
echo 'e_ject() {' | sudo tee --append /etc/bash.bashrc
echo '    dev=$(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')' | sudo tee --append /etc/bash.bashrc
echo '    echo $dev | grep " " # check if space is present, then two or more lines were selected' | sudo tee --append /etc/bash.bashrc
echo '    if [ $? -eq 0 ]; then echo "Two or more mounts matched, please pass more specific parameter"; return; fi' | sudo tee --append /etc/bash.bashrc
echo '    if [ -z $dev ]; then echo "No mounts contaning phrase [$1] found"; return; fi' | sudo tee --append /etc/bash.bashrc
echo '    2>/dev/null eject $dev;' | sudo tee --append /etc/bash.bashrc
echo '    i=1' | sudo tee --append /etc/bash.bashrc
echo '    for (( ; i < 10; i++ )); do ' | sudo tee --append /etc/bash.bashrc
echo '        if [ -z $(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'') ]; then' | sudo tee --append /etc/bash.bashrc
echo '            udisksctl power-off -b $dev; ' | sudo tee --append /etc/bash.bashrc
echo '            return' | sudo tee --append /etc/bash.bashrc
echo '        fi' | sudo tee --append /etc/bash.bashrc
echo '        sleep 1' | sudo tee --append /etc/bash.bashrc
echo '    done' | sudo tee --append /etc/bash.bashrc
echo '    echo "Takes long to unmount, had not attempted to power off"' | sudo tee --append /etc/bash.bashrc
echo '}; export -f e_ject' | sudo tee --append /etc/bash.bashrc

echo '' | sudo tee --append /etc/bash.bashrc

# does not work for liveUSB
if [ -e /home/$(id -u -n)/.profile ]; then
    echo '' >> ~/.profile
    echo '# use RAM for cache' >> /home/$(id -u -n)/.profile
    # use "" to allow $id expand in echo
    echo "mount /home/$(id -u -n)/.cache" >> /home/$(id -u -n)/.profile
    echo '' >> /home/$(id -u -n)/.profile
fi

exit

-----
!!! below moved to run_at_boot_config.sh

echo '# for tmpfs /var' >> /home/$(id -u -n)/.profile
echo 'mkdir /var/spool' >> /home/$(id -u -n)/.profile
echo 'mkdir /var/cache' >> /home/$(id -u -n)/.profile
echo 'ln -s /var_on_disk/lib /var/lib' >> /home/$(id -u -n)/.profile
echo 'ln -s /var_on_disk/spool/cron /var/spool/cron' >> /home/$(id -u -n)/.profile
echo 'ln -s /var_on_disk/cache/man /var/cache/man' >> /home/$(id -u -n)/.profile
echo 'ln -s /run/lock /var/lock' >> /home/$(id -u -n)/.profile
echo 'ln -s /run /var/run' >> /home/$(id -u -n)/.profile
