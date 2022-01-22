#!/bin/bash

# https://wiki.winehq.org/Ubuntu
# checking if repository is already added
grep winehq /etc/apt/sources.list /etc/apt/sources.list.d/*
if [ $? -ne 0 ]; then
    sudo dpkg --add-architecture i386
    cd ~ 
    wget -nc https://dl.winehq.org/wine-builds/winehq.key
    sudo apt-key add winehq.key
    rm winehq.key
#    sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ impish main'
    sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' 
    sudo apt-get update
fi

echo winehq-stable | apt_get -d
sudo sed --in-place '/winehq/d' $(grep winehq /etc/apt/sources.list /etc/apt/sources.list.d/* | awk 'BEGIN {FS=":"}{print $1}')
sudo apt-get update

# https://wiki.winehq.org/Gecko
path_to_gecko="/media/$(id -un)/usb/LM_20.2/wine-gecko"
if [ -e "$path_to_gecko" ]; then echo >&2 "folder for wine-gecko at $path_to_gecko already exists, exiting with error"; exit 1; fi
mkdir $path_to_gecko
mkdir $path_to_gecko/5.0 && cd $_
wget http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86.msi
wget http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86.tar.bz2
wget http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86_64.msi
wget http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86_64.tar.bz2

mkdir $path_to_gecko/6.0 && cd $_
wget http://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86.msi 
wget http://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86.tar.xz
wget http://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86_64.msi
wget http://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86_64.tar.xz

# https://wiki.winehq.org/Mono
path_to_mono="/media/$(id -un)/usb/LM_20.2/wine-mono"
if [ -e "$path_to_mono" ]; then echo >&2 "folder for wine-mono at $path_to_mono already exists, exiting with error"; exit 1; fi
mkdir $path_to_mono

mkdir $path_to_mono/5.1.1 && cd $_ # for our 6.0.1 wine
wget https://dl.winehq.org/wine/wine-mono/5.1.1/wine-mono-5.1.1-src.tar.xz
wget https://dl.winehq.org/wine/wine-mono/5.1.1/wine-mono-5.1.1-x86.msi
wget https://dl.winehq.org/wine/wine-mono/5.1.1/wine-mono-5.1.1-x86.tar.xz

mkdir $path_to_mono/7.0.0 && cd $_ # for 7.0.0 wine
wget https://dl.winehq.org/wine/wine-mono/7.0.0/wine-mono-7.0.0-dbgsym.tar.xz
wget https://dl.winehq.org/wine/wine-mono/7.0.0/wine-mono-7.0.0-src.tar.xz
wget https://dl.winehq.org/wine/wine-mono/7.0.0/wine-mono-7.0.0-tests.zip
wget https://dl.winehq.org/wine/wine-mono/7.0.0/wine-mono-7.0.0-x86.msi
wget https://dl.winehq.org/wine/wine-mono/7.0.0/wine-mono-7.0.0-x86.tar.xz

