#!/bin/bash

bashrc=/etc/bash.bashrc

#
# change prompt
#
grep 'bash prompt, LM original and setting it' "${bashrc}" 1>/dev/null
if [ $? -ne 0 ]; then
    echo '' | sudo tee --append $bashrc
    echo '# bash prompt, LM original and setting it'  | sudo tee --append $bashrc
    echo '# \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$'  | sudo tee --append $bashrc
    echo 'PS1='\''\[\033[01;34m\]\w\[\033[00m\]\$ '\''' | sudo tee --append $bashrc
fi

#
# add aliases
#
echo $'\n'"alias 'cpn=cp --no-clobber'" | sudo tee --append "${bashrc}" # do not overwrite an existing file
echo $'\n'"alias 'a-i=sudo apt-get install'" | sudo tee --append "${bashrc}" # do not overwrite an existing file
echo $'\n'"alias hi=history" | sudo tee --append "${bashrc}"

add_dict_alias(){
#    if [ "$(dict -D | awk '{print $1}' | grep $2)" ] ; then
    if [ "$(ls /usr/share/dictd | grep $2)" ] ; then # if run in chrooted dictd daemon still uses same database as before entering chroot, therefore check contents of default directory where databases are to be located (in accordance with dictd manpage)
        echo $'\n'"alias 'dict-$1=dict -d $2'" | sudo tee --append "${bashrc}"
    fi
}

if [ x != x`which dict` ]; then
    add_dict_alias english-gcide gcide
    add_dict_alias english-wordnet wn
    add_dict_alias english-wiki wikt-en-en
    add_dict_alias deutsche fd-deu-eng
    add_dict_alias german fd-eng-deu
    add_dict_alias français fd-fra-eng
    add_dict_alias french fd-eng-fra
fi

#
# add Readline Key Bindings:
#
echo $'\n'"bind '\"\C-h\": \"\C-e\`\\\"\C-a history -s \\\"\`2>&1 \C-j\"'" | sudo tee --append "${bashrc}" # add Ctrl-h - if command is entered and Ctrl-h pressed, cursor to move to end of line (Ctrl-e/C-e), '`' is to be added to end and then C-a causes cursor to move to beginning of the line and ' history -s `2>&1 ' to be added. Result is (per design) to save output of command to history (e.g. useful to copy 'not found, but can be installed with'). C-j is mentioned as ^J on wikipedia page "Control_character". `\C` seems to mean Ctrl. Command within `` is quoted (around ``) to prevent expantion when assigning to history

#
# add functions
#
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

    mounts="$(lsblk --paths --output PKNAME,PATH,FSTYPE,MOUNTPOINT,LABEL | grep --ignore-case "$1" | wc -l)"
    if [ "${mounts}" -ge 2 ]; then echo "ERROR: Two or more block devices matched, please pass more specific parameter"; return 1; fi
    if [ "${mounts}" -eq 0 ]; then echo "ERROR: No block devices contaning phrase [$1] found"; return 1; fi
    dev_name=" $(lsblk --paths --output PKNAME,PATH,FSTYPE,MOUNTPOINT,LABEL | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')"
    dev_path=" $(lsblk --paths --output PATH,PKNAME,FSTYPE,MOUNTPOINT,LABEL | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')"
    dev_mount="$(lsblk --paths --output MOUNTPOINT,PKNAME,PATH,FSTYPE,LABEL | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')"

    # unmounting; "umount" failed for btrfs on extended partition with "error finding object for block device 0:56", so changed to "udisksctl unmount"
    for (( i=1; i < ${attempts}; i++ )); do
        if [ -n "$(lsblk --paths --output MOUNTPOINT,PATH | grep "${dev_path}" | awk '\''{print $1}'\'')"  ] ; then # dev_path seems unique, so filter by it then check if dev_mount not empty already (no need to unmount if empty)
            udisksctl unmount --block-device "${dev_path}" && echo "${dev_path} unmounted (detached) from ${dev_mount}" && break
        else
            echo "${dev_path} not mounted"; break
        fi
        sleep 1
    done
    if [ $i -eq ${attempts} ]; then
        >&2 echo "ERROR: Takes long to unmount, seems NOT unmounted, had not attempted to power off"
        return 1
    fi

    # locking cypto (luks)
    for (( i=1; i < ${attempts}; i++ )); do
        if [ "$(lsblk --paths --output PKNAME,PATH,MOUNTPOINT | grep "${dev_path}" | grep --quiet --ignore-case "luks"; echo $?)" -eq 0 ]; then # not fool-proof against output having luks word in it even if it is not unlocked luks partition; TODO:think about it
            dev="${dev_name}" # as for luks PKNAME contains partition name whereas for non-luks PKNAME contains whole device (usually, but not always, for e.g. loop partition table type there is only one partition and so no parent partion, so PKNAME is empty), PATH contains partition
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

# mount via terminal
add_function 'm_ount_options' '
    if [ "${1}" = "-h" ] || [ "${1}" = "--help" ]; then
        if [ "$#" -eq 1 ]; then opt="with mount options as second parameter"; else opt="with mount options: ${2}"; fi
        echo "Code for mounting block device (e.g. USB stick), takes as parameter string to match for block devices by type, label, path; with mount options: ${opt}"
        return 0
    fi

    mounts="$(lsblk --paths --output PKNAME,PATH,FSTYPE,MOUNTPOINT,LABEL | grep --ignore-case "$1" | wc -l)"
    if [ "${mounts}" -ge 2 ]; then echo "ERROR: Two or more block devices matched, please pass more specific parameter"; return 1; fi
    if [ "${mounts}" -eq 0 ]; then echo "ERROR: No block devices contaning phrase [$1] found"; return 1; fi

    dev_type="$(lsblk --paths --output FSTYPE,PKNAME,PATH,MOUNTPOINT,LABEL | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')"
    dev_path="$(lsblk --paths --output PATH,FSTYPE,PKNAME,MOUNTPOINT,LABEL | grep --ignore-case "$1" | awk '\''{ print $1 }'\'')"

    if [ "${dev_type}" != "${dev_type/crypto/cryptofound}" ]; then # type contains word crypto
        dev_path="$(udisksctl unlock --block-device "${dev_path}" | awk '\''{ print $4 }'\'')" # e.g. unlocked /dev/sdc1  as /dev/dm-1.
    fi

    echo "Mount options are: ${2}"
    udisksctl mount --block-device "${dev_path%.}" --options "${2}" # removal of . at the end if it is there
'

add_function 'm_ount' '
    m_ount_options "$1" "ro,noatime"
'

add_function 'm_ountw' '
    m_ount_options "$1" "rw,noatime"
'

add_function 'Pound4Kilo' '
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Converts metric kilograms to pounds, one parameter (real or integer number)"
        return 0
    fi

    python -c "print($1/0.453)"
'

add_function 'Kilo4Pound' '
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Converts pounds to metric kilograms, one parameter (real or integer number)"
        return 0
    fi

    python -c "print($1*0.453)"
'
add_function 'Liter4Gallon' '
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Converts gallons to liters (qubic decimeters), one parameter (real or integer number)"
        return 0
    fi

    python -c "print($1*0.0254**3*231*1000)"
'

add_function 'Gallon4Liter' '
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Converts liters (qubic decimeters) to gallons, one parameter (real or integer number)"
        return 0
    fi

    python -c "print($1/0.0254**3/231/1000)"
'

add_function 'Liter4Oz' '
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Converts US customary fluid ounce (oz, 1/128 of a gallon) to liters (qubic decimeters), one parameter (real or integer number)"
        return 0
    fi
    gallons=`Liter4Gallon $1`
    python -c "print($gallons/128)"
'

add_function 'Oz4Liter' '
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Converts liters (qubic decimeters) to US customary fluid ounce (oz, 1/128 of a gallon), one parameter (real or integer number)"
        return 0
    fi
    gallons=`Gallon4Liter $1`
    python -c "print($gallons*128)"
'

add_function 'FInch4Meter' '
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Converts metric meters to feet and inches, one parameter (real or integer number)"
        return 0
    fi

    python -c "f2m=0.3048;i2m=0.0254;f=int($1/f2m); i=($1-f*f2m)/i2m; print(str(f)+\"'\''\"+str(i)+\"\\\"\");print(str(f)+\"'\''\"+str(round(i))+\"\\\"\")"
'

add_function 'Meter4FInch' '
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Converts feet and inches to metric meters, two parameters: feet and inches (real or integer numbers)"
        return 0
    fi

    python -c "f2m=0.3048;i2m=0.0254;print($1*0.3048+$2*0.0254)"
'

add_function 'Fahrenheit4Celsius' '
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Converts Celsius degrees to Fahrenheit scale, one parameter (real or integer number)"
        return 0
    fi
    # f - Fahrenheit; c - Celsius; w - water; fr - freezing; bo - boiling
    python -c "fwfr=32;fwbo=212;cwfr=0;cwbo=100; print(fwfr+($1-cwfr)*(fwfr-fwbo)/(cwfr-cwbo))"
'

add_function 'Celsius4Fahrenheit' '
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Converts Fahrenheit degrees to Celsius scale, one parameter (real or integer number)"
        return 0
    fi
    # f - Fahrenheit; c - Celsius; w - water; fr - freezing; bo - boiling
    python -c "fwfr=32;fwbo=212;cwfr=0;cwbo=100; print(cwfr+($1-fwfr)*(cwfr-cwbo)/(fwfr-fwbo))"
'
add_function 'BMI' '
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Body Mass Index, two parameters: kilos and meters (real or integer numbers)"
        return 0
    fi

    python -c "print($1/$2/$2)"
'
