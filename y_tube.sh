#!/bin/bash

# 2023/07 List produced by `yt-dlp --list-subs URL` contained certain subtitles but on download they did not contain useful info, therefore adding language codes encountered and filtering out empty later
# "--format-sort ext" helped to select "--prefer-free-formats" over "quality" (see "Filtering Formats" in README of yt-dlp)
params=" --prefer-free-formats --format-sort ext --write-info-json --write-description --write-sub --write-auto-sub --sub-langs en-en,en,fr,fr-en,fr-en-US,de,de-en,de-en-US,ru,ru-en,ru-en-US,uk,uk-en,uk-en-US " # from 2023/07 translations from English are codes as ??-en

# see yt-dlp README for syntax, h looks for up to 1200p no less than 800p horizontal, trying for <=30 fps 1) merged, then 2) separate video+audio then drop fps constraint
# l looks for up to 800p no less than 600p horizontal, trying for <=30 fps 1) merged, then 2) separate video+audio then 3) drop minimum horizontal constraint
format_params_h=' --format best[height<=1200][height>=800][fps<=30]/bv[height<=1200][height>=1800][fps<=30]+ba/bv[height<=1200][height>=1800]+ba/bv[height<=1200]+ba '
format_params_l=' --format best[height<=800][height>=600][fps<=30]/bv[height<=800][height>=600][fps<=30]+ba/bv[height<=800][fps<=30]+ba '

# for install and update arguments
source "$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
# help
help_message="  Calls yt-dlp $params [formats in accordance with h|l] [other parameters] URL
  To prioritize video quality use args l for 720 quality or lower and h for 1080p quality.
(h: $format_params_h) (l: $format_params_h)
  Other parameters given on command line are passed to yt-dlp.
  Usage: $script_name [h|l] [other parameters] URL\n"
display_help "$help_message$common_help"
# ====== #

params_add=""
case $1 in
    "h" ) params_add="$format_params_h" ; shift ;;
    "l" ) params_add="$format_params_l" ; shift ;;
esac
#    set -x # bash option "Print commands and their arguments as they are executed"
yt-dlp $params $params_add $@
#    set +x
ret_status=$?
if [ $ret_status -ne 0 ];then
    echo "  Exit status not 0 (fail?) after code to try to download, one hypothesis is that selected video/audio format is not available, in such case use --list-formats parameter to get list of formats"
    exit $ret_status
fi

URL=${!#} # ! bash's indirect substitution, get last positional parameter
video_id=$(echo "$URL" | awk 'BEGIN { FS = "=" } { print $2 }')

# deleting subtitle files that are empty - w/out words (only timestamps), 2023/07 noted there are those like "de" when "de-en" were introduced.

# but need to check if any matching files present, otherwise * is not expanded by shell.
ls *"$video_id"*vtt &>/dev/null
if [ $? -ne 0 ] ; then exit 3 ; fi

# for f in $(ls | grep "$video_id" | grep vtt) ; do # makes many parts of file names as separate f
for f in *"$video_id"*vtt  ; do

    lines_with_digits=$(grep "[0-9]" "$f" | wc -l)
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

# delete duplicate subtitles (i.e. en and en-en), works if only two files found; ! string comparison seems to be needing escape in bash
find . -name "*$video_id*.en[-.][ev][nt]*" -exec sh -c 'if [ $# -eq 2 ] ; then cmp --quiet "${1}" "${2}" && if [ "${1}" \< "${2}" ] ; then rm "${1}" ; else rm "${2}" ; fi ; fi' sh {} + # [2]

# make "en" default (picking first from sorted by name I guess) for mpv
find . -name "*$video_id*.en.vtt" -exec bash -c 'mv "${1}" "${1/.en.vtt/.En.vtt}"' bash {} \; # [2]

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

[2]
https://unix.stackexchange.com/questions/389705/understanding-the-exec-option-of-find
# find's exec works as filter for next command,e.g.
   -exec grep -q 'test' {} ';' -exec echo {} ';'
# shell's -c accepts arguments
sh -c 'echo  "$1"' sh "printed"

