#!/bin/bash

# useful info who eject works:
# https://unix.stackexchange.com/questions/35508/eject-usb-drives-eject-command/83587

# Not sure a function need to be exported each time of login (initially was part of login scripts), but count not find an asnwer to that in man bash and do not want to google now.
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

# commant to remount ro
echo '' | sudo tee --append /etc/bash.bashrc
echo 'mnt_ro() {' | sudo tee --append /etc/bash.bashrc
echo '    dev=$(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')' | sudo tee --append /etc/bash.bashrc
echo '    echo $dev | grep " " # check if space is present, then two or more lines were selected' | sudo tee --append /etc/bash.bashrc
echo '    if [ $? -eq 0 ]; then echo "Two or more mounts matched, please pass more specific parameter"; return; fi' | sudo tee --append /etc/bash.bashrc
echo '    if [ -z $dev ]; then echo "No mounts contaning phrase [$1] found"; return; fi' | sudo tee --append /etc/bash.bashrc
echo '    sudo mount -o remount,ro $dev;' | sudo tee --append /etc/bash.bashrc
echo '}; export -f mnt_ro' | sudo tee --append /etc/bash.bashrc
echo '' | sudo tee --append /etc/bash.bashrc

# commant to remount rw
echo '' | sudo tee --append /etc/bash.bashrc
echo 'mnt_rw() {' | sudo tee --append /etc/bash.bashrc
echo '    dev=$(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')' | sudo tee --append /etc/bash.bashrc
echo '    echo $dev | grep " " # check if space is present, then two or more lines were selected' | sudo tee --append /etc/bash.bashrc
echo '    if [ $? -eq 0 ]; then echo "Two or more mounts matched, please pass more specific parameter"; return; fi' | sudo tee --append /etc/bash.bashrc
echo '    if [ -z $dev ]; then echo "No mounts contaning phrase [$1] found"; return; fi' | sudo tee --append /etc/bash.bashrc
echo '    sudo mount -o remount,rw $dev;' | sudo tee --append /etc/bash.bashrc
echo '}; export -f mnt_ro' | sudo tee --append /etc/bash.bashrc
echo '' | sudo tee --append /etc/bash.bashrc

