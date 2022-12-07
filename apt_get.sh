#!/bin/bash

# apt-config output see man apt-config
# $() command substitution see man bash 
# now in /var/cache/apt/archives but made hopefully more future proof

#if [ ! -f $script_path ]; then

# for install, update arguments, help message output
source common_arguments_to_scripts.sh
# help
help_message="  The Script is written to read from standard input.
  Script is written to download deb packages with dependancies and stores them locally.
  Lines to be read are expected to be names of packages (not fully qualified) from standard input, use 
  1st argument (if not omitted) that is not -d, -i or for help used as location for downloaded files.

  Example: $script_name -i /media/alex/usb/LM_20.2/debs /home/alex/Documents/dpkg_orig_status
  usage: $script_name [-i | -d ] [location_to_store] [dpkg_status_file_location] < filename
  or echo -e 'package_unqualified_name[\npackage_unqualified_name] etc' | $script_name [-i | -d] [location_to_store] [dpkg_status_file_location]
  -i means install right after downloaded.
  -d means download only to default path with default_local_status of dpkg.\n"
display_help "$help_message$common_help"
# ===== #

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi
if [ "x${work_path}" = "x" ] ; then work_path=/media/ramdisk ; fi
default_local_debs="$software_path_root/debs"
default_local_status="$software_path_root/apt_dpkg_state/dpkg_orig_status"
status_path_tmp="$work_path/status"

# if no arguments, use these:
if [ $# -eq 0 ]
  then
    set -- '-i' $default_local_debs $default_local_status
    echo "$0 was called without any parameters, in that case default parameters are used: '-i' $default_local_debs $default_local_status"
    no_parameters_supplied=1 # for displaying messages later in case of error          
fi

# if only -i as argument, install from local
# if printpath, print local debs path to stdout (used in install_debs.sh)
if [ $# -eq 1 ]
  then
    if [ $1 = "-i" ] # install after download to default path (if not downloaded already)
      then
        set -- '-i' $default_local_debs       
    elif [ $1 = "-d" ] # download only to default path with default_local_status of dpkg
      then
        set -- $default_local_debs $default_local_status
    elif [ $1 = "printpath" ]
      then
        printf "%s" $default_local_debs
        exit
    fi
fi

eval $(apt-config shell CACHE Dir::Cache)
eval $(apt-config shell ARCHIVES Dir::Cache::archives)

# from man bash:
# brace { after $ "serve to protect the variable to be expanded from characters immediately following it which could be interpreted as part of the name."
debs_cache_folder=/${CACHE}/${ARCHIVES}

# argument $0 is name of the script
# = should be used with the test command for POSIX conformance.
if [ $1 = "-i" ]
  then
    install_now=yes
    # shift arguments left by 1 (default)
    shift
fi

# make named pipe to collect errors for packets and output all errors at the end
# mkfifo errors_apt_get
# named pipes are useful when one need input to hang and wait to output, also it mixes sequence (when sereval outputs echo > pipe and then one read from pipe cat < pipe)
errors_apt_get=/errors_apt_get

status_path=$2

# -z true if length is 0, -n for !=0
# POSIX way [] not [[ ]]
# both ; and new line can serve as separators
substitute_status(){
    if [ -n "$status_path" ]
      then
        cp $status_path $status_path_tmp
        copy_exit_status=$?
        if [ $copy_exit_status -ne 0 ];then # error
            echo >&2 "Exiting on error $copy_exit_status after trying to create temporary dpkg status file"
            if [ -v no_parameters_supplied ]; then 
                echo >&2 "$0 was called without any parameters, calling with '-i' parameter means same except for no status file substitution"
            fi   
            exit $err
        fi

        # now /var/lib/dpkg/status but made hopefully more future proof   
        eval $(apt-config shell STATUS Dir::State::status)

        # if [ ! -f $STATUS.orig ] then ; sudo cp $status_path $STATUS.orig ; fi
        sudo mv $STATUS $STATUS.bak;
        sudo ln -s $status_path_tmp $STATUS;
    fi
}

substitute_status

restore_status(){
    if [ -n "$status_path" ]
      then
        sudo mv --force $STATUS.bak $STATUS;
        rm $status_path_tmp
    fi
}

# call above in case of ctrl-c pressed
exit_on_ctrl_c(){
# man bash: 
# -v varname
#     True if the shell variable varname is set (has been assigned a value).
    if [ -v connect_restore ]; then 
      if [ $connect_restore -eq 1 ]; then nmcli networking on; fi
    fi
    restore_status
    echo -e "\nstopped manually"
    exit 0
}
trap 'exit_on_ctrl_c' SIGINT

# man bash
# Command substitution allows the output of a command to replace the command name.  There are two forms:
# $(command) or `command`
# Bash performs the expansion by executing command in a subshell environment and replacing the command substitution with the standard output of the command, 
# !!!!!! ----- with any trailing newlines deleted -------- !!!!!!!!!!!
install_local(){
    if [ -n "$install_now" ]
      then
        # added x and 2>/dev/null for case of making of liveUSB iso, when with chroot nmcli outputs error
        # x is needed because no output does not mean empty string as I've understood by try-and-error last time
        if [ "x$(2>/dev/null nmcli networking connectivity)" = "xfull" ]; then
            nmcli networking off
            connect_restore=1
        else
            connect_restore=0
        fi
        #nmcli radio wifi off
        restore_status
        # apt uses _apt user, so that user should have access to the folder with debs. udisks makes username folder in media giving access to the user via ACL, so:
        sudo setfacl -m u:_apt:x /media/$(id -un)


        # process needed confugurations settings 
        # added to make selection during wireshark install
        # https://unix.stackexchange.com/questions/367866/how-to-choose-a-response-for-interactive-prompt-during-installation-from-a-shell

        # https://stackoverflow.com/questions/10929453/read-a-file-line-by-line-assigning-the-value-to-a-variable
        # IFS= (or IFS='') prevents leading/trailing whitespace from being trimmed.
        # -r prevents backslash escapes from being interpreted.
        # man bash
        # IFS    The Internal Field Separator that is used for word splitting after expansion and to split lines into words with the read builtin command.  The default value is ``<space><tab><newline>''.
        # sudo DEBIAN_FRONTEND=noninteractive apt-get -y install wireshark

        # man bash
        # -f file
        #      True if file exists and is a regular file.
        debconf_values_file=$debs_storage_folder/_debconf-set-selections
        if [ -f $debconf_values_file ]; then
# not needed as debconf-set-selections can read from a file, have not been tested to work before commented:
#            while IFS= read -r line; do
#                printf "%s" $line | sudo debconf-set-selections
#            done < $debconf_values_file
            sudo debconf-set-selections $debconf_values_file 
        fi

        # apt takes case of pre-dependencies processing debs in proper order, dpkg does not
        # sudo dpkg --recursive --install $debs_storage_folder && 1>&2 echo "    Package(s)  $line  installed"    
        # apt lacks --assume-yes option, so changing to apt-get
        
        # DEBIAN_FRONTEND=noninteractive added for wireshark-qt - see above
        sudo DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes $debs_storage_folder/*.deb 
        Eval=$?

        if [ $Eval -eq 0 ];then
            echo "    Package(s)  $line  installed (at least seems like it)"
        else
            echo "Package  $line  NOT installed (at least seems like it)" | 1>&2 sudo tee --append $errors_apt_get
        fi
        
        sudo setfacl -x u:_apt /media/$(id -un)
        substitute_status
        if [ $connect_restore -eq 1 ]; then nmcli networking on; fi
    fi
}

# from man apt-get:
# clears out the local repository of retrieved package files. It removes everything but the lock file from
# /var/cache/apt/archives/ and /var/cache/apt/archives/partial/
sudo apt-get clean

# from man bash
# read [-ers] [-a aname] [-d delim] [-i text] [-n nchars] [-N nchars] [-p prompt] [-t timeout] [-u fd] [name ...]
#   One  line  is  read from the standard input, or from the file descriptor fd supplied as an argument to the -u option,

echo "Enter names of the packages to process (if not supplied via echo before the run):"
while read line; do

    if [ -n "$line" ];then # allow for empty lines

        debs_storage_folder=$1/$line
        if [ -d $debs_storage_folder ] ; then 
            1>&2 echo "folder "\`"$debs_storage_folder"\`" exists, not copying of deb files"
            install_local            
        else
            1>&2 echo "    Package(s)  $line  being downloaded..."
            # download-only of deb packages including dependencies
            # TODO see [1] maybe change to apt-get download -o Dir::Cache="./" -o Dir::Cache::archives="./"?
            # though script is coded to copy anyway and only in case of success, if download to e.g. USB directly, in case of failure
            # would need to delete from USB, though maybe download to ramdisk?
            sudo apt-get install --download-only --assume-yes $line

            # get return status of last command
            Eval=$?

            if [ $Eval -eq 0 ];then

                # interestingly folder can be named like /dev////sda same as /dev/sda
                # ! that is for that case : on command line in parameters one can terminate with / or not - user friendly        
                mkdir --parents $debs_storage_folder # -p --parents no error if existing, make parent directories as needed
                cp $debs_cache_folder/*.deb $debs_storage_folder
                # chmod --recursive a+rw $debs_storage_folder
                # chmod a+rw $debs_storage_folder
                1>&2 echo "    Package(s)  $line  downloaded (at least seems like it)"
                sudo apt-get clean
                install_local
            else
                echo "Package  $line  is NOT downloaded, downloaded deb files were not copied from cache to specified location (at least seems like it)" | 1>&2 sudo tee --append $errors_apt_get
                sudo apt-get clean
            fi # download success
        fi # existense of folder
    fi # empty line
done # reading lines of names of packages

# call with parameter $2, why parameter???
# restore_status $2

restore_status

if [ -e $errors_apt_get ]; then 
    echo "=====    Errors during script:     ====="
    1>&2 cat $errors_apt_get
    echo "===== End of errors during script: ====="
    sudo rm $errors_apt_get
fi

exit

# ------- commments on code --------------------

# what is the difference of the below?
# (from https://linuxhint.com/30_bash_script_examples/#t17)
# (from https://linuxhint.com/30_bash_script_examples/#t19)
    # (( i=i+1 ))
    # i=$(($i+1))    


# from man bash:
# Bash is Copyright (C) 1989-2018 by the Free Software Foundation, Inc.
# ?      Expands to the exit status of the most recently executed foreground pipeline.
# The  `$'  character  introduces  parameter  expansion,  command substitution, or arithmetic expansion.  
# The parameter name or symbol to be expanded may be enclosed in braces, which are optional but serve 
# to protect the variable to be expanded from characters immediately following it which could be interpreted as part of the name.



# from man bash:
# Bash is Copyright (C) 1989-2018 by the Free Software Foundation, Inc.
#       if list; then list; [ elif list; then list; ] ... [ else list; ] fi
#              The if list is executed.  If its exit status is zero, the then list is executed.  Otherwise, each elif list is executed in turn, and  if  its  exit  status  is
#              zero, the corresponding then list is executed and the command completes.  Otherwise, the else list is executed, if present.  The exit status is the exit status
#              of the last command executed, or zero if no condition tested true.
#
#       Conditional expressions are used by the [[ compound command and the test and [ builtin commands to test file attributes and perform string and arithmetic comparisons.
#       The test abd [ commands determine their behavior based on the number of arguments; see the descriptions of those commands for any other command-specific actions.

#       test expr
#       [ expr ]
#              Return  a  status  of 0 (true) or 1 (false) depending on the evaluation of the conditional expression expr.  Each operator and operand must be a separate argu‐
#              ment.  Expressions are composed of the primaries described above under CONDITIONAL EXPRESSIONS.  test does not accept any options, nor does it accept  and  ig‐
#              nore an argument of -- as signifying the end of options.
#              test and [ evaluate conditional expressions using a set of rules based on the number of arguments.
#
#              0 arguments
#                     The expression is false.
#              1 argument
#                     The expression is true if and only if the argument is not null.

#       [[ expression ]]
#              Return a status of 0 or 1 depending on the evaluation of the conditional expression expression.  Expressions are composed of the primaries described below  un‐
#              der  CONDITIONAL EXPRESSIONS.  Word splitting and pathname expansion are not performed on the words between the [[ and ]]; tilde expansion, parameter and vari‐
#              able expansion, arithmetic expansion, command substitution, process substitution, and quote removal are performed.  Conditional operators such as  -f  must  be
#              unquoted to be recognized as primaries.
#
#              When used with [[, the < and > operators sort lexicographically using the current locale.
#
#       See the description of the test builtin command (section SHELL BUILTIN COMMANDS below) for the handling of parameters (i.e.  missing parameters).

[1]
https://unix.stackexchange.com/questions/683777/why-apt-get-does-not-download-all-dependencies-in-download-only-mode
https://stackoverflow.com/questions/13756800/how-to-download-all-dependencies-and-packages-to-directory

PACKAGES="wget unzip"
apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests \
  --no-conflicts --no-breaks --no-replaces --no-enhances \
  --no-pre-depends ${PACKAGES} | grep "^\w")



