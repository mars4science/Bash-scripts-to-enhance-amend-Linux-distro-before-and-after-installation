#!/bin/bash

# script does one task, makes sense to abort if fails
trap 'err=$?; echo >&2 "Exiting $0 on error $err"; sleep 10; exit $err' ERR

# install scripts etc. from:
default_source_software_path=/home/$(id -un)/Documents/Projects/Scripts_git

# man realink:
# Note realpath(1) is the preferred command to use for canonicalization functionality.
#       -f, --canonicalize
#              canonicalize  by  following  every  symlink in every component of the given name recur‐
#              sively; all but the last component must exist
script_path="$(realpath "$0")"

# not only file name, can remove suffix too
script_name=$(basename $script_path .sh)

if [[ ! $# -eq 0 && $1 = "install" ]]; then
  install_path=$(get_install_path.sh)
  sudo cp $script_path $install_path
  sudo chmod o+x $install_path
  sudo ln --force -s $install_path/$script_name.sh $install_path/$script_name # --force : remove existing destination files
  echo copied script $script_path to $install_path, to run use $script_name with or w/out .sh suffix
  exit
  # setuid bit is prohibited for scripts
fi

if [[ ! $# -eq 0 && $1 = "update" ]];then
  # update in /usr/local/bin from /home/alex/Documents/Projects/Scripts/r_sync.sh
  source_path=$default_source_software_path/$script_name.sh
  sudo cp $source_path $script_path
  sudo chmod o+x $script_path
  echo updated script $script_path from $source_path
  exit
  # setuid bit is prohibited for scripts 
fi

# --- main code ---

printf "%s" $default_source_software_path

