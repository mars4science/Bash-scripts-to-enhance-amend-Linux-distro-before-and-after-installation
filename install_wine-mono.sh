#!/bin/bash

path_to_mono="/media/$(id -un)/usb/LM_20.2/wine-mono"
# man bash -e file True if file exists
if [ ! -e "$path_to_mono" ]; then echo >&2 "wine-mono path $path_to_mono not found, exiting with error"; exit 1; fi

wine_version=$(wine --version | awk 'BEGIN {FS = "-"}{print $2}')

wine_path="$(realpath $(which wine))"
if [ "$wine_path" = "/opt/wine-stable/bin/wine" ];then
    path_to_install=/opt/wine-stable/share/wine/mono
elif [ "$wine_path" = "/usr/bin/wine-stable" ];then
    path_to_install=/usr/share/wine/mono
else 
    echo >&2 "---Error: not found suitable wine path (found: $wine_path) to add wine-mono"; exit 1
fi

# mono version for wine versions taken from table on https://wiki.winehq.org/Mono
if [ $wine_version = "7.0" ];then
    sudo mkdir --parents $path_to_install
    find $path_to_mono/7.0.0 -name wine-mono-7.0.0-x86.tar.xz -exec sudo tar x -f "{}" --atime-preserve --one-top-level="$path_to_install" \;
    # if [ $? ];then echo "copied mono to $path_to_install"; else echo "error: maybe NOT copied mono to $path_to_install"; fi
    echo "copied (installed) mono to $path_to_install"
elif [ $wine_version = "6.0.1" ];then
    sudo mkdir --parents $path_to_install
    find $path_to_mono/5.1.1 -name wine-mono-5.1.1-x86.tar.xz -exec sudo tar x -f "{}" --atime-preserve --one-top-level="$path_to_install" \;
    # if [ $? ];then echo "copied mono to $path_to_install"; else echo "error: maybe NOT copied mono to $path_to_install"; fi
    echo "copied (installed) mono to $path_to_install"
else
    echo >&2 "---Error: not found suitable wine version (found: $wine_version) to add wine-mono"; exit 1
fi

