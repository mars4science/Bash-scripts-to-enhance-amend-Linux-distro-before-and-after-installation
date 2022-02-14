#!/bin/bash

# ===== common scripts arguments ===== #
# used in other scripts via source ./common_arguments_to_scripts.sh

# man realink:
# Note realpath(1) is the preferred command to use for canonicalization functionality.
#       -f, --canonicalize
#              canonicalize  by  following  every  symlink in every component of the given name recur‐
#              sively; all but the last component must exist
script_path="$(realpath "$0")"

# not only file name, can remove suffix too
script_name=$(basename $script_path .sh)

# a line below is not needed as basename does it (removed specific suffix)
# script_name="${script_name%%.*}" # remove .sh

install_path=$(get_install_path.sh)
source_path=$(get_source_path.sh)/$script_name.sh
common_help="usage: "\""$script_name update"\"" - to update script itself from "\""$source_path"\"

# need to install and update it, so next line would stands in the way
# if [ $script_name = "common_arguments_to_scripts" ]; then echo "common_arguments_to_scripts.sh is not supposed to be run on its own, exiting"; exit 1; fi

# installs from where it was run to designated path
if [[ ! $# -eq 0 && $1 = "install" ]]; then
  sudo cp $script_path $install_path
  sudo chmod o+x $install_path
  sudo ln --force -s $install_path/$script_name.sh $install_path/$script_name # --force : remove existing destination files
  echo copied script $script_path to $install_path, to run use $script_name with or w/out .sh suffix
  exit
  # setuid bit is prohibited for scripts
fi

# updates current file from designated path
if [[ ! $# -eq 0 && $1 = "update" ]];then
  sudo cp $source_path $script_path
  sudo chmod o+x $script_path
  echo updated script $script_path from $source_path
  exit
  # setuid bit is prohibited for scripts 
fi

# outputs help message (variable is to be set in the scripts have sourced this one to overwrite one set here)
help_message="This is a script to be sourced in other scripts"
if [ ! $# -eq 0 ] && [ $1 = "help" -o $1 = "--help" -o $1 = "-h"  -o $1 = "?" ];then
    printf "$help_message"
    exit 0
fi

# ===== end of common scripts arguments ===== #

# some previous thoughts about checking for timestamps during update run
# if [ $0 -nt $install_path ]; then
# if [ ! -f $script_path ]; then
