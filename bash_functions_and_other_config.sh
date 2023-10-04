#!/bin/bash

bashrc=/etc/bash.bashrc

grep 'bash prompt, LM original and setting it' "${bashrc}"
if [ $? -ne 0 ]; then
    echo '' | sudo tee --append $bashrc
    echo '# bash prompt, LM original and setting it'  | sudo tee --append $bashrc
    echo '# \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$'  | sudo tee --append $bashrc
    echo 'PS1='\''\[\033[01;34m\]\w\[\033[00m\]\$ '\''' | sudo tee --append $bashrc
fi

add_function(){
    # remove previous version if in the file
    sudo perl -0777 -pi -e "s/$1().*export -f $1//sg" "${bashrc}" # sg modifiers for perl regex: g - global, replace more than once; s - makes "." cross line boundaries

    echo '' | sudo tee --append "${bashrc}"
    echo "$1() {$2}; export -f $1" | sudo tee --append "${bashrc}"
    echo '' | sudo tee --append "${bashrc}"
}

# useful info how eject works:
# https://unix.stackexchange.com/questions/35508/eject-usb-drives-eject-command/83587

# Not sure a function need to be exported each time of login (initially was part of login scripts), but could not find an asnwer to that in man bash and do not want to google now.
# Therefore to be on the safe side below (adding to user profile) is expected to be Ok (multiple re-export did not output any errors):

# simplier version
# echo 'e_ject() { 2>/dev/null eject $1;udisksctl power-off -b $1; }; export -f e_ject' >> /home/$(id -u -n)/.profile

# to use: e_ject name
# name is searched (grepped) in mount output of all mounts, expected to be present on one line only, but seems to work fine even if on multiple mounts e.g. for e_ject sdb with multiple partitions USB stick. On my system both eject and udisksctl work with partition (/dev/sdbx) parameter.
# 2>/dev/null is added due to eject outputing an error each time, but result seemed correct.
# Not sure a function need to be exported each time of login, but count not find an asnwer to that in man bash and do not want to google now. Therefore to be on the safe side below (adding to user profile) is expected to be Ok (multiple re-export did not output any errors):

# ADDED: sometimes produced error at time of power-off, hypothesis is that umounting took longer than exit from eject, so added a cycle

# awk fields separator is space by default
# for awk '' are needed cause $1 is awk notation, if "" than would be expanded by the shell

add_function 'e_ject' '
    dev=$(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')
    echo $dev | grep " " # check if space is present, then two or more lines were selected
    if [ $? -eq 0 ]; then echo "Two or more mounts matched, please pass more specific parameter"; return; fi
    if [ -z $dev ]; then echo "No mounts contaning phrase [$1] found"; return; fi
    2>/dev/null eject $dev;
    i=1
    for (( ; i < 10; i++ )); do
        if [ -z $(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'') ]; then
            udisksctl power-off -b $dev;
            return
        fi
        sleep 1
    done
    echo "Takes long to unmount, had not attempted to power off"
'

# command to remount ro
add_function 'mntro' '
    dev=$(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')
    echo $dev | grep " " # check if space is present, then two or more lines were selected
    if [ $? -eq 0 ]; then echo "Two or more mounts matched, please pass more specific parameter"; return; fi
    if [ -z $dev ]; then echo "No mounts contaning phrase [$1] found"; return; fi
    sudo mount -o remount,ro $dev;
'

# command to remount rw
add_function 'mntrw' '
    dev=$(mount | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')
    echo $dev | grep " " # check if space is present, then two or more lines were selected
    if [ $? -eq 0 ]; then echo "Two or more mounts matched, please pass more specific parameter"; return; fi
    if [ -z $dev ]; then echo "No mounts contaning phrase [$1] found"; return; fi
    sudo mount -o remount,rw $dev;
'

# run geth offline
add_function 'gethh' '
    echo - Starting geth console in offine mode
    echo - To generate and sign transaction to send 0.5 as 16th transaction use e.g.:
    echo > personal.signTransaction\({from: eth.accounts[0], to: \"0x40_hex_symbols_address\", value: web3.toWei\(0.5, \"ether\"\), nonce: 15, gas: 21000, gasPrice: 5},\"password_set_during_import\"\)
    echo - To send transaction e.g. copy \"raw:\" field from output and use MyCrypto
    echo - To generate address from secret key run from bash:
    echo $ geth --password file_with_password_to_set.txt account import file_with_key.txt
    sleep 3
    geth --nodiscover --maxpeers 0 console
'

# git: pull all tracked local branches
add_function 'git_pull' '
    echo "- pulling (fast-forward only) all tracked branches from [origin] remote; assumes names of local branches and corresponding branches on remote are same (to push all branches: git push --all <remote repository>)"
    if [ "x$1" = "x" ]; then set -- "origin"; fi
    git fetch $1 || return 1
    current_branch=$(git branch | grep "*" | sed "s/[ *]*//") # getting name of current branch via asterisk
    for branch in $(git branch | sed "s/[ *]*//") ; do # remove spaces and asterisk
        git checkout $branch && git fetch $1 $branch && git merge --ff-only FETCH_HEAD
    done
    echo "- checking out to branch where function was called from"
    git checkout $current_branch
'

# git: merge current branch into all other local branches
add_function 'git_merge' '
    echo "- merging (fast-forward only) current branch into all other local branches"
    1>/dev/null git branch || return 1 # return in case was run not in valid git repo
    current_branch=$(git branch | grep "*" | sed "s/[ *]*//") # getting name of current branch via asterisk
    for branch in $(git branch | sed "s/[ *]*//") ; do # remove spaces and asterisk
        if [ $branch != $current_branch ] ; then git checkout $branch && git merge --ff-only $current_branch; fi
    done
    echo "- checking out to branch where function was called from"
    git checkout $current_branch
'
