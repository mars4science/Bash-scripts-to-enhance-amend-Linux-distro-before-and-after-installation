#!/bin/bash

# to dwonload all branches
# https://stackoverflow.com/questions/67699/how-to-clone-all-remote-branches-in-git/7216269#7216269
# git clone --mirror path/to/original path/to/dest/.git
# cd path/to/dest
# git config --bool core.bare false
# git checkout anybranch


trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# https://stackoverflow.com/questions/20348097/bash-extract-string-before-a-colon
# why is this link here?

# for "install" and "update" arguments
source common_arguments_to_scripts.sh

# help
if [ $1 = "--help" -o $1 = "-h" ];then
    echo "usage: run $script_name when in working tree of a repository"
    exit 0
fi

# https://stackoverflow.com/questions/70252065/how-to-return-to-bare-repository-for-compact-storage-undo-a-checkout-in-git/70253143#70253143
# maybe below line would work and would be enough
git switch --orphan empty_long_name

