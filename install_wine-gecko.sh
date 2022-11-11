#!/bin/bash

# https://unix.stackexchange.com/questions/97101/how-to-catch-an-error-in-a-linux-bash-script/254675
# you can specify a command that's executed in case a command returns a nonzero status, with the ERR trap, 
# trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR
# here non-zero status is processed other way

path_to_gecko="${software_path_root}/wine-gecko"
# man bash -e file True if file exists
if [ ! -e "$path_to_gecko" ]; then echo >&2 "wine-gecko path $path_to_gecko not found, exiting with error"; exit 1; fi

# info grep
# Normally the exit status is 0 if a line is selected, 1 if no lines were selected, and 2 if an error occurred.
wine --version | grep wine-5

# get return status of last command
Eval5=$?

wine --version | grep wine-6
Eval6=$?

wine --version | grep wine-7
Eval7=$?

wine_path=$(realpath $(which wine))
if [ $wine_path = "/opt/wine-stable/bin/wine" ];then
    path_to_install=/opt/wine-stable/share/wine/gecko
elif [ $wine_path = "/usr/bin/wine-stable" ];then
    path_to_install=/usr/share/wine/gecko
else 
    echo >&2 "---Error: not found suitable wine path (found: $wine_path) to add wine-mono"; exit 1
fi
    
# looks like where is no "wine" way to find out where wine configs are, so just put from experience with Linun Mint:

# man bash
# test and [ evaluate conditional expressions using a set of rules
#              based on the number of arguments.
# 1 argument
#                     The expression is true if and only if the argument is not
#                     null.
# cannot use c language (C language) way of if not 0 then true, not [ $Eval5 ] but [ $Eval5 eq 0 ] - true
# also space before ] is important and needed for syntax 

# on https://wiki.winehq.org/Gecko downloads: bz2 for 5 and xz for 6
# locations to install to are found by try-and-error on my system (LM 20.2)
if [ $Eval5 -eq 0 ];then
    # man mkdir
    #  -p, --parents
    #          no error if existing, make parent directories as needed
    sudo mkdir --parents $path_to_install
    find /$path_to_gecko/5.0 -name '*.bz2' -exec sudo tar x -f "{}" --atime-preserve --one-top-level="$path_to_install" \;
    # below checks resuls of ? I guess, not errors on archive extract
    # if [ $? ];then echo "copied gecko to $path_to_install"; else echo "error: maybe NOT copied gecko to $path_to_install"; fi
    echo "copied (installed) gecko to $path_to_install"
elif [ $Eval6 -eq 0 -o $Eval7 -eq 0 ];then # 6 mono is latest as of 2022/1/21
    sudo mkdir --parents $path_to_install
    find $path_to_gecko/6.0 -name '*.xz' -exec sudo tar x -f "{}" --atime-preserve --one-top-level="$path_to_install" \;
    # if [ $? ];then echo "copied gecko to $path_to_install"; else echo "error: maybe NOT copied gecko to $path_to_install"; fi
    echo "copied (installed) gecko to $path_to_install"
else
    echo "---Error: not found suitable wine version to add wine-gecko"
    wine --version
fi

