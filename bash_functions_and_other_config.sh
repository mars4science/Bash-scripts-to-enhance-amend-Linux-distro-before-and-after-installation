#!/bin/bash

bashrc=/etc/bash.bashrc

grep 'bash prompt, LM original and setting it' "${bashrc}" 1>/dev/null
if [ $? -ne 0 ]; then
    echo '' | sudo tee --append $bashrc
    echo '# bash prompt, LM original and setting it'  | sudo tee --append $bashrc
    echo '# \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$'  | sudo tee --append $bashrc
    echo 'PS1='\''\[\033[01;34m\]\w\[\033[00m\]\$ '\''' | sudo tee --append $bashrc
fi

add_function(){
    # remove previous version if in the file; $'\n' is line break in bash (using $'\' notation)
    sudo perl -0777 -pi -e "s/"$'\n'"$1().*?export -f $1"$'\n'$'\n'"//sg" "${bashrc}" # sg modifiers for perl regex: g - global, replace more than once; s - makes "." cross line boundaries. "?" needed to make regex lazy, otherwise greedy: selects up to past occurence of "export -f", not first

    echo $'\n'"$1() {$2}; export -f $1"$'\n' | 1>/dev/null sudo tee --append "${bashrc}"
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

    attempts=5

    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Code for powering off removable block device (e.g. USB stick), takes as parameter string to match for mount points and/or block devices"
        return 0
    fi

    mounts="$(lsblk --paths --output PKNAME,PATH,MOUNTPOINT | grep --ignore-case "$1" | wc -l)"
    if [ "${mounts}" -ge 2 ]; then echo "ERROR: Two or more block devices matched, please pass more specific parameter"; return 1; fi
    if [ "${mounts}" -eq 0 ]; then echo "ERROR: No block devices contaning phrase [$1] found"; return 1; fi
    dev_name="$(lsblk --paths --output PKNAME,PATH,MOUNTPOINT | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')"
    dev_path="$(lsblk --paths --output PKNAME,PATH,MOUNTPOINT | grep --ignore-case "$1" | awk '\''{ print $2 }'\'')"
    dev_mount="$(lsblk --paths --output PKNAME,PATH,MOUNTPOINT | grep --ignore-case "$1" | awk '\''{ print $3 }'\'')"

    # unmounting
    for (( i=1; i < ${attempts}; i++ )); do
        if [ -n "$(lsblk --paths --output PKNAME,PATH,MOUNTPOINT | grep "${dev_path}" | awk '\''{print $3}'\'')"  ] ; then # dev_path seems unique, dev_mount can be empty already
            umount "${dev_mount}" && echo "${dev_mount} unmounted" && break
        else
            echo "${dev_path} not mounted"; break
        fi
        sleep 1
    done
    if [ $i -eq ${attempts} ]; then
        >&2 echo "ERROR: Takes long to unmount, seems NOT unmounted, had not attempted to power off"
        return 1
    fi

    # unlocking luks
    for (( i=1; i < ${attempts}; i++ )); do
        if [ "$(lsblk --paths --output PKNAME,PATH,MOUNTPOINT | grep "${dev_path}" | grep --quiet --ignore-case "luks"; echo $?)" -eq 0 ]; then
            dev="${dev_name}" # as for luks PKNAME contains partition name whereas for non-luks PKNAME contains whole device, PATH contains partition
            udisksctl lock --block-device "${dev_name}" && break # no need for sudo, instead of: sudo cryptsetup close "${dev_path}"
        else
            dev="${dev_path}"
            echo "${dev_path} not locked"
            break
        fi
        sleep 1
    done
    if [ $i -eq ${attempts} ]; then
        >&2 echo "ERROR: Takes long to lock luks device ${dev_name}, seems unmounted but still locked, had not attempted to power off"
        return 1
    fi

    # powering off
    eject $"${dev}" 2>/dev/null ; # does not seem to work lately but left just in case

    for (( i=1; i < ${attempts}; i++ )); do
        if [ -n "$(lsblk --paths --output PKNAME,PATH,MOUNTPOINT | grep "${dev}")" ]; then
            msg=$(udisksctl power-off --block-device "${dev}" 2>&1) && echo "${dev} powered off" && return 0
            if [ -n "$(echo "${msg}" | grep "No usb device")" ]; then
                >&2 echo "ERROR: ${msg}, seems unmounted but powering off failed"
                return 1
            fi
        fi
        sleep 1
    done
    >&2 echo "ERROR: Takes long to power off, seems unmounted but powering off failed"
    return 1
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
