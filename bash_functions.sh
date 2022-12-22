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

bashrc=/etc/bash.bashrc

echo '' | sudo tee --append $bashrc
# echo 'e_ject() { dev=$(mount | grep --ignore-case $1 | awk --field-separator " " '\''{ FS = " " ; print $1 ; exit }'\'');2>/dev/null eject $dev;udisksctl power-off -b $dev; }; export -f e_ject' | sudo tee --append $bashrc
# awk separator is space by default
# for awk '' are needed cause $1 is awk notation, if "" than would be expanded by the shell
echo 'e_ject() {' | sudo tee --append $bashrc
echo '    dev=$(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')' | sudo tee --append $bashrc
echo '    echo $dev | grep " " # check if space is present, then two or more lines were selected' | sudo tee --append $bashrc
echo '    if [ $? -eq 0 ]; then echo "Two or more mounts matched, please pass more specific parameter"; return; fi' | sudo tee --append $bashrc
echo '    if [ -z $dev ]; then echo "No mounts contaning phrase [$1] found"; return; fi' | sudo tee --append $bashrc
echo '    2>/dev/null eject $dev;' | sudo tee --append $bashrc
echo '    i=1' | sudo tee --append $bashrc
echo '    for (( ; i < 10; i++ )); do ' | sudo tee --append $bashrc
echo '        if [ -z $(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'') ]; then' | sudo tee --append $bashrc
echo '            udisksctl power-off -b $dev; ' | sudo tee --append $bashrc
echo '            return' | sudo tee --append $bashrc
echo '        fi' | sudo tee --append $bashrc
echo '        sleep 1' | sudo tee --append $bashrc
echo '    done' | sudo tee --append $bashrc
echo '    echo "Takes long to unmount, had not attempted to power off"' | sudo tee --append $bashrc
echo '}; export -f e_ject' | sudo tee --append $bashrc

echo '' | sudo tee --append $bashrc

# command to remount ro
echo '' | sudo tee --append $bashrc
echo 'mntro() {' | sudo tee --append $bashrc
echo '    dev=$(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')' | sudo tee --append $bashrc
echo '    echo $dev | grep " " # check if space is present, then two or more lines were selected' | sudo tee --append $bashrc
echo '    if [ $? -eq 0 ]; then echo "Two or more mounts matched, please pass more specific parameter"; return; fi' | sudo tee --append $bashrc
echo '    if [ -z $dev ]; then echo "No mounts contaning phrase [$1] found"; return; fi' | sudo tee --append $bashrc
echo '    sudo mount -o remount,ro $dev;' | sudo tee --append $bashrc
echo '}; export -f mntro' | sudo tee --append $bashrc
echo '' | sudo tee --append $bashrc

# command to remount rw
echo '' | sudo tee --append $bashrc
echo 'mntrw() {' | sudo tee --append $bashrc
echo '    dev=$(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')' | sudo tee --append $bashrc
echo '    echo $dev | grep " " # check if space is present, then two or more lines were selected' | sudo tee --append $bashrc
echo '    if [ $? -eq 0 ]; then echo "Two or more mounts matched, please pass more specific parameter"; return; fi' | sudo tee --append $bashrc
echo '    if [ -z $dev ]; then echo "No mounts contaning phrase [$1] found"; return; fi' | sudo tee --append $bashrc
echo '    sudo mount -o remount,rw $dev;' | sudo tee --append $bashrc
echo '}; export -f mntrw' | sudo tee --append $bashrc
echo '' | sudo tee --append $bashrc

# run geth offline
echo '' | sudo tee --append $bashrc
echo 'gethh() {' | sudo tee --append $bashrc
echo '    echo - Starting geth console in offine mode' | sudo tee --append $bashrc
echo '    echo - To generate and sign transaction to send 0.5 as 16th transaction use e.g.:' | sudo tee --append $bashrc
echo '    echo > personal.signTransaction\({from: eth.accounts[0], to: \"0x40_hex_symbols_address\", value: web3.toWei\(0.5, \"ether\"\), nonce: 15, gas: 21000, gasPrice: 5},\"password_set_during_import\"\)' | sudo tee --append $bashrc
echo '    echo - To send transaction e.g. copy \"raw:\" field from output and use MyCrypto' | sudo tee --append $bashrc
echo '    echo - To generate address from secret key run from bash:' | sudo tee --append $bashrc
echo '    echo $ geth --password file_with_password_to_set.txt account import file_with_key.txt' | sudo tee --append $bashrc
echo '    sleep 3' | sudo tee --append $bashrc
echo '    geth --nodiscover --maxpeers 0 console' | sudo tee --append $bashrc
echo '}; export -f gethh' | sudo tee --append $bashrc
echo '' | sudo tee --append $bashrc

# git: pull all tracked local branches
echo '' | sudo tee --append $bashrc
echo 'git_pull() {' | sudo tee --append $bashrc
echo '    echo - pulling (fast-forward only) all tracked local branches from origin remote' | sudo tee --append $bashrc
echo '    git fetch || return 1' | sudo tee --append $bashrc
echo '    orig_branch=$(git branch | grep "*" | sed "s/[ *]*//") # getting name of current branch via asterisk' | sudo tee --append $bashrc
echo '    for branch in $(git branch | sed "s/[ *]*//") ; do # remove spaces and asterisk' | sudo tee --append $bashrc
echo '        git checkout $branch && git merge --ff-only FETCH_HEAD' | sudo tee --append $bashrc
echo '    done' | sudo tee --append $bashrc
echo '    echo - checking out to branch where function was called from ' | sudo tee --append $bashrc
echo '    git checkout $orig_branch' | sudo tee --append $bashrc
echo '}; export -f git_pull' | sudo tee --append $bashrc
echo '' | sudo tee --append $bashrc

