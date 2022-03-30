#!/bin/bash

params=" --write-info-json --write-description --write-auto-sub --sub-langs en-en,en " # encountered both "en-en" and "en"

# TODO default location, current folder for now
# for downloaded data
# default_location=/media/$(id -un)/data/_all/Misc_vids
# if [ ! -d $default_location ]; then default_location=/media/data/_all/Misc_vids; fi

# for install and update arguments
source common_arguments_to_scripts.sh
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
        "h" ) params_add=" -f 271+251 -- ";;
# [1] decided not to check formats before try to download to save resources on accessing youtube twice ... yt-dlp --list-formats $2 | grep 271 ;;
        "l" ) params_add=" -f 22 -- " ;;
    esac
    yt-dlp $params $params_add $2
    if [ $? -eq 1 ];then 
        echo "exit status 1 (fail?) after code to try to download, hypothesis is that selected format is not available; "
        echo "next code to try without format arguments"
        yt-dlp $params $2
    fi
else
    yt-dlp $params $1
fi
    echo
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

man bash
[[ expression ]]
       An  additional  binary operator, =~, is available, with the same precedence as == and !=.  When it is used, the string to the right of the operator
       is considered a POSIX extended regular expression and matched accordingly (as in regex(3)).  The return value is 0 if the string matches  the  pat‐
       tern,  and  1 otherwise.  If the regular expression is syntactically incorrect, the conditional expression's return value is 2.  If the nocasematch
       shell option is enabled, the match is performed without regard to the case of alphabetic characters.  Any part of the  pattern  may  be  quoted  to
       force  the  quoted  portion  to be matched as a string.  Bracket expressions in regular expressions must be treated carefully, since normal quoting
       characters lose their meanings between brackets.  If the pattern is stored in a shell variable, quoting the variable expansion  forces  the  entire
       pattern  to  be matched as a string.  Substrings matched by parenthesized subexpressions within the regular expression are saved in the array vari‐
       able BASH_REMATCH.  The element of BASH_REMATCH with index 0 is the portion of the string matching the entire regular expression.  The  element  of
       BASH_REMATCH with index n is the portion of the string matching the nth parenthesized subexpression.
