#!/bin/bash

# to download all branches
# https://stackoverflow.com/questions/67699/how-to-clone-all-remote-branches-in-git/7216269#7216269

trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# for "install" and "update" arguments
source "$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
# help
help_message="  Clones remote/original repository to local as mirrow one (as tested clones all branches that way). Then changes config file to one that looks as one for regular repo as many git commands do not work on/in repository with core.bare true, some work differently with fetch set for mirroring.
  Usage: $script_name path_to_original_git [path_to_dest_folder, . (current folder) if omitted]\n"
display_help "$help_message$common_help"
# ====== #

if [ $# -eq 0 -o $# -gt 2 ];then
    echo "$0 was called without any parameters or too many, one/two parameter(s) is(are) expected, use -h for help"
    exit          
fi

# help
if [ $1 = "--help" -o $1 = "-h" ];then
    echo ""
    exit 0
fi

if [ $# -eq 2 ]; then cd "$2"; fi

git clone --mirror "$1" "./.git"
git config --bool core.bare false
sed --in-place -- "s|fetch = +refs/\*:refs/\*|fetch = +refs/heads/*:refs/remotes/origin/*|" .git/config
sed --in-place -- "/mirror = true/d" .git/config

if [ $# -eq 2 ]; then cd -; fi  # change directory back from "$2"

# ??? decided not to do that after answer to my question on SO that it is not supported, may use git-archive, git-branch w/out it to extract parts of the tree
# git config --bool core.bare false

