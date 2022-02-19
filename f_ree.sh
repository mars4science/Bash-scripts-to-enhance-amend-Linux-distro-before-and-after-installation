#!/bin/bash

# to delete usually unneeded files in memory gets low on booted to RAM system

# ====== #
source common_arguments_to_scripts.sh
# help
help_message="  For current user: deletes caches, empties Trash, deletes wine user files/data in user prefix folder.
  Usage: $script_name\n"
display_help "$help_message$common_help"
# ===== #

remove_if_exists() {
    if [ -d $1 ]; then rm --recursive $1; fi
}

remove_if_exists ~/.cache
remove_if_exists ~/.wine
remove_if_exists ~/.local/share/wineprefixes
remove_if_exists ~/.local/share/Trash

exit

# ============= comments below ================== #
several positional parameters can be supplied to the function

man bash:

A  shell function is an object that is called like a simple command and executes a compound command with a new set of positional parameters.  Shell
       functions are declared as follows:

       name () compound-command [redirection]
       function name [()] compound-command [redirection]
              This defines a function named name.  The reserved word function is optional.  If the function reserved word is supplied, the parentheses are
              optional.   The body of the function is the compound command compound-command (see Compound Commands above).  That command is usually a list
              of commands between { and }, but may be any command listed under Compound Commands above, with one exception: If the function reserved  word
              is used, but the parentheses are not supplied, the braces are required.  compound-command is executed whenever name is specified as the name
              of a simple command.  When in posix mode, name may not be the name of one of the POSIX special builtins.  Any redirections (see  REDIRECTION
              below)  specified  when a function is defined are performed when the function is executed.  The exit status of a function definition is zero
              unless a syntax error occurs or a readonly function with the same name already exists.  When executed, the exit status of a function is  the
              exit status of the last command executed in the body.  (See FUNCTIONS below.)

