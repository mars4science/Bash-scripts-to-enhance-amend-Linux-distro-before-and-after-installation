#!/bin/bash

path_to_mono="${software_path_root}/wine-mono"
# man bash -e file True if file exists
if [ ! -e "$path_to_mono" ]; then echo >&2 "wine-mono path $path_to_mono not found, exiting with error"; exit 1; fi

wine_version=$(wine --version | awk 'BEGIN {FS = "-"}{print $2}')

wine_path="$(realpath $(which wine))"
if [[ ("$wine_path" = "/opt/wine-stable/bin/wine") || ("$wine_path" = "/opt/wine-devel/bin/wine") ]] ; then
    path_to_install=/opt/wine-stable/share/wine/mono
elif [[ ("$wine_path" = "/usr/bin/wine-stable") || ("$wine_path" = "/usr/bin/wine-devel") ]] ; then
    path_to_install=/usr/share/wine/mono
else 
    echo >&2 "---Error: not found suitable wine path (found: $wine_path) to add wine-mono"; exit 1
fi

# mono version for wine versions taken from table on https://wiki.winehq.org/Mono
if [ "$wine_version" = "7.22" ] ; then mono_archive=wine-mono-7.4.0-x86.tar.xz ; 
elif [ "$wine_version" = "7.0" ] ; then mono_archive=wine-mono-7.0.0-x86.tar.xz ; 
elif [ "$wine_version" = "6.0.1" ] ; then mono_archive=wine-mono-5.1.1-x86.tar.xz ; 
else
    echo >&2 "---Error: not found suitable wine version (found: $wine_version) to add wine-mono"; exit 1
fi

sudo mkdir --parents $path_to_install
find $path_to_mono -name $mono_archive -exec sudo tar x -f "{}" --atime-preserve --one-top-level="$path_to_install" \;
# if [ $? ];then echo "copied mono to $path_to_install"; else echo "error: maybe NOT copied mono to $path_to_install"; fi
echo "copied (installed) mono to $path_to_install"

