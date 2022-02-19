    #!/bin/bash

# to download all branches
# https://stackoverflow.com/questions/67699/how-to-clone-all-remote-branches-in-git/7216269#7216269
# git clone --mirror path/to/original path/to/dest/.git
# cd path/to/dest
# git config --bool core.bare false
# git checkout anybranch

trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# for "install" and "update" arguments
source common_arguments_to_scripts.sh
# help
help_message="  Clones remote/original repository to local as bare one (as tested clones all branches that way). Then changes config to core.bare false to prepare for futher usage as many git commands do not work on/in repository with core.bare true.
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
git config core.bare false

# cd "$2"

# decided not to do that after answer to my question on SO that it is not supported, may use git-archive, git-branch w/out it to extract parts of the tree
# git config --bool core.bare false

