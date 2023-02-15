#!/bin/bash

# script does one task, makes sense to abort if fails
trap 'err=$?; echo >&2 "Exiting $0 on error $err"; sleep 10; exit $err' ERR

# install scripts etc. to:
default_local_software_path=/usr/local/bin

# if no arguments, main code (added 'if' to prevent recursion as the script is used in common_arguments_to_scripts.sh):
if [ $# -eq 0 ]; then
  printf "%s" $default_local_software_path
  exit
fi

# ====== #
source "$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
# help
help_message="  prints to standard output path to install additional software like bin files for 'install' command of the added scripts.
  Usage: $script_name\n"
display_help "$help_message$common_help"
# ===== #

