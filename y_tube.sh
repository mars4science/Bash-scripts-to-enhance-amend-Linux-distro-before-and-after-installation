#!/bin/bash

# 2023/07 List produced by `yt-dlp --list-subs URL` contained certain subtitles but on download they did not contain useful info, therefore adding language codes encountered and filtering out empty later
# "--format-sort ext" helped to select "--prefer-free-formats" over "quality" (see "Filtering Formats" in README of yt-dlp)
params=" --prefer-free-formats --format-sort ext --write-info-json --write-description --write-auto-sub --sub-langs en-en,en,fr,fr-en,fr-en-US,de,de-en,de-en-US,ru,ru-en,ru-en-US,uk,uk-en,uk-en-US " # from 2023/07 translations from English are codes as ??-en

# for install and update arguments
source "$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
# help
help_message="  calls yt-dlp $params [formats in accordance with args] URL
Args l for 720 quality and h for 1440p quality.
if path is given as argument, it is passed to tabs files are backed up to that location.
  Usage: $script_name [l|h] URL\n"
display_help "$help_message$common_help"
# ====== #

params_add=" -- "
if [ $# -eq 2 ]; then
    case $1 in
# see yt-dlp README for syntax, h looks for up to 1200p no less than 800p horizontal, trying for <=30 fps 1) merged, then 2) separate video+audio then drop fps constraint
        "h" ) params_add=' -f best[height<=1200][height>=800][fps<=30]/bv[height<=1200][height>=1800][fps<=30]+ba/bv[height<=1200][height>=1800]+ba/bv[height<=1200]+ba -- ';;
# h looks for up to 800p  no less than 600p horizontal, trying for <=30 fps 1) merged, then 2) separate video+audio then 3) drop minimum horizontal constraint
        "l" ) params_add=' -f best[height<=800][height>=600][fps<=30]/bv[height<=800][height>=600][fps<=30]+ba/bv[height<=800][fps<=30]+ba -- ';;
    esac
#    set -x # bash option "Print commands and their arguments as they are executed"
    yt-dlp $params $params_add $2
#    set +x
    if [ $? -eq 1 ];then 
        echo "exit status 1 (fail?) after code to try to download, hypothesis is that selected format is not available; "
#        echo "next code to try without format arguments"
#        yt-dlp $params $2
        exit 1
    fi
    URL=$2
else
    yt-dlp $params $1
    URL=$1
fi
    echo

# deleting subtitle files that are empty - w/out words (only timestamps), 2023/07 noted there are those like "de" when "de-en" were introduced.
video_id=$(echo "$URL" | awk 'BEGIN { FS = "=" } { print $2 }')

# for f in $(ls | grep "$video_id" | grep vtt) ; do # makes many parts of file names as separate f
for f in *"$video_id"*vtt  ; do

    lines_with_digits=$(grep [0-9] "$f" | wc -l)
    lines_empty=$(grep -E "^[ \t]*$" "$f" | wc -l)
    lines_total=$(cat "$f" | wc -l)

    # as of 2023/07 there are 3 additional lines at start of the file, I make 10 as some guess of future-proof
    if [[ $(( lines_total - lines_with_digits - lines_empty )) -le 10 ]] ; then rm "$f" ; fi

done

# rename subtitle files for loading by mpv (e.g. suffix de-en.vtt to de.vtt)
for f in *"$video_id"*-en.vtt ; do
    f1="${f/-en.vtt/.vtt}"
    if [ ! -e "${f1}" ] && [ -e "${f}" ] ; then
        mv "${f}" "${f1}"
    fi
done
for f in *"$video_id"*-en-US.vtt ; do
    f1="${f/-en-US.vtt/.vtt}"
    if [ ! -e "${f1}" ] && [ -e "${f}" ] ; then
        mv "${f}" "${f1}"
    fi
done

exit

---
[1]
https://askubuntu.com/questions/1093843/how-to-split-input-to-two-pipes
https://superuser.com/questions/557256/reading-the-same-stdin-with-two-commands-in-bash/557291#557291
program1 | tee >(program2) >(program3)
-
yt-dlp --list-formats https://www.youtube.com/watch?v=IrBlWB2bxQU | tee >(grep --extended-regexp "^22" ) >(grep --extended-regexp "^18";aaa="sss") >/dev/null
echo $aaa # empty as expected, grep was run in a subshell, so see above: decided not to check
---

#    some other way to distinguish files
#    digits=$(tr -dc '[:digit:]' < "$f" | wc -c)
#    number_of_digits=${#digits}
#    size=$(stat "$f" | grep -i size | awk '{ print $2 }')

