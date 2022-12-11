#!/bin/bash

# Tested for Linux Mint 20.2 Cinnamon 64-bit and Linux Mint 21 Cinnamon 64-bit
# Uses apt and dpkg
# Help message below might explain usage and what the script does

# for install, update arguments, help message output
source common_arguments_to_scripts.sh
# help
help_message="  The Script is written to read from standard input.
  Script is written to download deb packages with dependancies and stores them locally.
  Lines to be read are expected to be names of packages (not fully qualified) from standard input, use 
  1st argument (if not omitted) that is not -d, -i or for help used as location for downloaded files.

  Example: $script_name -i /media/alex/usb/LM_20.2/debs /home/alex/Documents/apt_dpkg_state
  usage: $script_name [-i | -d ] [location_to_store] [folder with dpkg status file (dpkg_orig_status e.g. copied from /var/lib/dpkg/status) and apt sources locations, (sources.list file and sources.list.d folder, e.g. copied from /etc/apt)] < filename
  or echo -e 'package_unqualified_name"'[\\n'"package_unqualified_name] etc' | $script_name [-i | -d] [location_to_store] [folder with dpkg status file and apt sources location]
  -i means install right after downloaded.
  -d means download only to default path with default location of dpkg status file and apt sources.
  If dpkg status and/or apt sources not found at supplied location, substitution not done.\n"
display_help "$help_message$common_help"
# ===== #

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi
if [ "x${work_path}" = "x" ] ; then work_path=/media/ramdisk ; fi
default_local_debs="$software_path_root/debs"

# where to take from dpkg status file and apt sources if not supplied as argument (passed as one argument via shift)
default_local_apt_dpkg_folder="$software_path_root/apt_dpkg_state/"

# where to put dpkg status file and apt sources temporarity (for script to work, apt might update them?)
apt_dpkg_folder_tmp="$work_path/apt_dpkg_state"
status_file_path_tmp="$apt_dpkg_folder_tmp/dpkg_status"
sources_file_path_tmp="$apt_dpkg_folder_tmp/sources.list"
sources_dir_path_tmp="$apt_dpkg_folder_tmp/sources.list.d"

if [ -e "$apt_dpkg_folder_tmp" ]
    then
        echo >&2 "Exiting as folder set to be used as temporary already exists: $apt_dpkg_folder_tmp"
        exit 1
fi

# ----- processing command line arguments ----- #

# if no arguments, use these:
if [ $# -eq 0 ]
  then
    set -- '-i' $default_local_debs $default_local_apt_dpkg_folder
    echo "$0 was called without any parameters, in that case default parameters are used: '-i' $default_local_debs $default_local_apt_dpkg_folder"
    no_parameters_supplied=1 # for displaying messages later in case of error          
fi

# if only -i as argument, install from local
# if printpath, print local debs path to stdout (used in install_debs.sh)
if [ $# -eq 1 ]
  then
    if [ $1 = "-i" ] # install after download to default path (if not downloaded already)
      then
        set -- '-i' $default_local_debs       
    elif [ $1 = "-d" ] # download only to default path with default location for dpkg status and apt sources
      then
        set -- $default_local_debs $default_local_apt_dpkg_folder
    elif [ $1 = "printpath" ]
      then
        printf "%s" $default_local_debs
        exit
    fi
fi

# argument $0 is name of the script
# = should be used with the test command for POSIX conformance.
if [ $1 = "-i" ]
  then
    install_now=yes
    # shift arguments left by 1 (default)
    shift
fi


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


eval $(apt-config shell CACHE Dir::Cache)
eval $(apt-config shell ARCHIVES Dir::Cache::archives)

# from man bash:
# brace { after $ "serve to protect the variable to be expanded from characters immediately following it which could be interpreted as part of the name."
debs_cache_folder=/${CACHE}/${ARCHIVES}


# make named pipe to collect errors for packets and output all errors at the end
# mkfifo errors_apt_get
# named pipes are useful when one need input to hang and wait to output, also it mixes sequence (when sereval outputs echo > pipe and then one read from pipe cat < pipe)
errors_apt_get=/errors_apt_get


# below derives paths from command line argument
apt_dpkg_folder=$2
status_file_path=$apt_dpkg_folder/dpkg_orig_status
sources_file_path=$apt_dpkg_folder/sources.list
sources_dir_path=$apt_dpkg_folder/sources.list.d

# ----- functions definitions ----- #

# -z true if length is 0, -n for !=0 (for strings)
# POSIX way [] not [[ ]]
# both ; and new line can serve as separators

substitute_dpkg_status(){
    if [ $copy_status_file_exit_status -eq 0 ] ; then
        sudo mv $STATUS_FILE $STATUS_FILE.bak;
        sudo ln -s $status_file_path_tmp $STATUS_FILE;
    fi
}

substitute_apt_status(){
    if [ $copy_sources_file_exit_status -eq 0 ] ; then
        sudo mv $SOURCES_FILE $SOURCES_FILE.bak;
        sudo ln -s $sources_file_path_tmp $SOURCES_FILE;
    fi

    if [ $copy_sources_dir_exit_status -eq 0 ] ; then
        sudo mv $SOURCES_DIR $SOURCES_DIR.bak;
        sudo ln -s $sources_dir_path_tmp $SOURCES_DIR;
    fi

    # even if sources not substituted, refresh is often useful
    echo === mext line: sudo apt-get update ===
    sudo apt-get update
    echo === line after line with update ===
}


substitute_status(){
    if [ -d "$apt_dpkg_folder" ]
      then
        mkdir --parent $apt_dpkg_folder_tmp
        cp $status_file_path $status_file_path_tmp
        copy_status_file_exit_status=$?
        cp $sources_file_path $sources_file_path_tmp
        copy_sources_file_exit_status=$?
        cp --recursive $sources_dir_path $sources_dir_path_tmp
        copy_sources_dir_exit_status=$?

        # `man bash` outputs that expressions can be combined with e.g. && for [[ ]], but does not say for [ ]
        if [[ ($copy_status_file_exit_status -ne 0) &&  ($copy_sources_file_exit_status -ne 0) && ($copy_sources_dir_exit_status -ne 0) ]];then # error
            echo >&2 "Exiting on error, neither dpkg status file not both apt sources file and folder were copied with success"
            if [ -v no_parameters_supplied ]; then 
                echo >&2 "$0 was called without any parameters, calling with '-i' parameter means same except for no dpkg status file / apt sources substitution"
            fi   
            exit $err
        fi

        # noted there are /var/lib/dpkg/status, /etc/apt/sources.list, single file /etc/apt/sources.list.d/official-package-repositories.list, but made hopefully more future proof
        eval $(apt-config shell STATUS_FILE Dir::State::status) # full path
        eval $(apt-config shell ETC_DIR Dir::Etc) # gave etc/apt
        eval $(apt-config shell SOURCES_FILE Dir::Etc::sourcelist) # only last part of path
        eval $(apt-config shell SOURCES_DIR Dir::Etc::sourceparts) # only last part of path

        SOURCES_FILE=/$ETC_DIR/$SOURCES_FILE
        SOURCES_DIR=/$ETC_DIR/$SOURCES_DIR

        substitute_dpkg_status
        substitute_apt_status
    fi
}


restore_dpkg_status(){
    if [ $copy_status_file_exit_status -eq 0 ] ; then
        sudo mv --force $STATUS_FILE.bak $STATUS_FILE
        # rm $status_file_path_tmp
    fi
}

restore_apt_status(){
    if [ $copy_sources_file_exit_status -eq 0 ] ; then
        sudo mv --force $SOURCES_FILE.bak $SOURCES_FILE
        # rm $sources_file_path_tmp
    fi

    if [ $copy_sources_dir_exit_status -eq 0 ] ; then
        sudo rm $SOURCES_DIR # line added as `mv` wrote for line below cannot overwrite non-directory .. with directory (script made a link)
        sudo mv $SOURCES_DIR.bak $SOURCES_DIR
    fi

    if [[ ($copy_sources_file_exit_status -eq 0) || ($copy_sources_dir_exit_status -eq 0) ]] ; then
        echo === after sources substitution reversed mext line: sudo apt-get update  ===
        sudo apt-get update # sources were substituted, update back with original sources
        echo === line after line with update ===
    fi
}

restore_status(){
    if [ -d "$apt_dpkg_folder_tmp" ]
      then
        restore_dpkg_status
        restore_apt_status
        rm --recursive "$apt_dpkg_folder_tmp"
    fi
}

# Bash performs the expansion of command substituion by executing command in a subshell environment and replacing the command substitution with the standard output of the command,
# !!!!!! ----- with any trailing newlines deleted -------- !!!!!!!!!!!

install_local(){
    if [ -n "$install_now" ]
      then
        # added x and 2>/dev/null for case of making of liveUSB iso, when with chroot nmcli outputs error
        # x is needed because no output does not mean empty string as I''ve understood by try-and-error last time
        if [ "x$(2>/dev/null nmcli networking connectivity)" = "xfull" ]; then
            nmcli networking off
            connect_restore=1
        else
            connect_restore=0
        fi
        #nmcli radio wifi off
        restore_dpkg_status
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
        sudo DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends $debs_storage_folder/*.deb
        Eval=$?

        if [ $Eval -eq 0 ];then
            echo "    Package(s)  $line  installed (at least seems like it)"
        else
            echo "    Package  $line  NOT installed (at least seems like it)" | 1>&2 sudo tee --append $errors_apt_get
        fi
        
        sudo setfacl -x u:_apt /media/$(id -un)
        substitute_dpkg_status
        if [ $connect_restore -eq 1 ]; then nmcli networking on; fi
    fi
}

# ----- start of main part of code where functions are called ----- #

substitute_status

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


[1]
https://unix.stackexchange.com/questions/683777/why-apt-get-does-not-download-all-dependencies-in-download-only-mode
https://stackoverflow.com/questions/13756800/how-to-download-all-dependencies-and-packages-to-directory

PACKAGES="wget unzip"
apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests \
  --no-conflicts --no-breaks --no-replaces --no-enhances \
  --no-pre-depends ${PACKAGES} | grep "^\w")



