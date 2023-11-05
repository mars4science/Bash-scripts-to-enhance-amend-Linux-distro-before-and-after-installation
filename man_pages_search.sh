#!/bin/bash

# to find manual pages containing all of multiple strings (arguments)

# ====== #
source "$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
# help
help_message="  Searches sources files of the system reference manual pages for containing all arguments as literal strings (case insensitive) in any order (aka --global-apropos but for multiple arguments as 'man' application itself for some reason seems to have no such option)\nLists paths to found man pages files, man page is file name sans .gz
  Usage: $script_name <string> <string> [<string>...]\n"
display_help "$help_message$common_help"
# ===== #

pages=$(man --ignore-case --global-apropos --path -- "$1" | LC_ALL=C sort --unique)
shift

while [ "$#" -gt 0 ] && [ -n "${pages}" ]; do
  pages=$(zgrep --ignore-case --files-with-matches --fixed-strings -- "$1" ${pages})
  shift
done

if [ -n "${pages}" ]; then
  man --path -- ${pages} # print list of found man files
else
  printf "No matching man pages found.\n"
fi
