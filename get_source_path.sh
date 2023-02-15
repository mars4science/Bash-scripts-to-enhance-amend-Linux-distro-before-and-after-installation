#!/bin/bash

# script does one task, makes sense to abort if fails
trap 'err=$?; echo >&2 "Exiting $0 on error $err"; sleep 10; exit $err' ERR

# install scripts etc. from:
default_source_software_path=/home/$(id -un)/Documents/Projects/Scripts_git

# if no arguments, main code (added 'if' to prevent recursion as the script is used in common_arguments_to_scripts.sh):
if [ $# -eq 0 ]; then
  printf "%s" $default_source_software_path
  exit
fi

# ====== #
source "$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
# help
help_message="  prints for standard output path to install additional software like bin files.
  Usage: $script_name\n"
display_help "$help_message$common_help"
# ===== #


