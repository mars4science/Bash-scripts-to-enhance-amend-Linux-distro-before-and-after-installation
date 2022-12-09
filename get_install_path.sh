#!/bin/bash

# script does one task, makes sense to abort if fails
trap 'err=$?; echo >&2 "Exiting $0 on error $err"; sleep 10; exit $err' ERR

# install scripts etc. to:
default_local_software_path=/usr/local/bin

# script_path=$0 # $0 gives full (?"or relative path"? where have I read that?: footnote [1], might be some issues with symbolic links)

script_path="$(realpath "$0")"

# not only file name, can remove suffix too
script_name=$(basename $script_path .sh)

# && does not execute second part if first gets false, -a for test / [] does execute
if [[ ! $# -eq 0 && $1 = "install" ]]; then
  install_path=$default_local_software_path
  sudo cp $script_path $install_path
  sudo chmod o+x $install_path
  sudo ln --force -s $install_path/$script_name.sh $install_path/$script_name # --force : remove existing destination files
  echo copied script $script_path to $install_path, to run use $script_name with or w/out .sh suffix
  exit
  # setuid bit is prohibited for scripts
fi

if [[ ! $# -eq 0 && $1 = "update" ]];then
  source_path=$(get_source_path.sh)/$script_name.sh
  sudo cp $source_path $script_path
  sudo chmod o+x $script_path
  echo updated script $script_path from $source_path
  exit
  # setuid bit is prohibited for scripts 
fi

# --- main code ---

printf "%s" $default_local_software_path

exit

[1]
https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel

#!/bin/bash
echo "pwd: `pwd`"
echo "\$0: $0"
echo "basename: `basename $0`"
echo "dirname: `dirname $0`"
echo "dirname/readlink: $(dirname $(readlink -f $0))"

Running this script in my home dir, using a relative path:

>>>$ ./whatdir.sh
pwd: /Users/phatblat
$0: ./whatdir.sh
basename: whatdir.sh
dirname: .
