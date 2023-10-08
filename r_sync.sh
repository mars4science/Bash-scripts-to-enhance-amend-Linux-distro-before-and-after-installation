#!/bin/bash

trap 'err=$?; echo >&2 "Exiting $0 on error $err"; exit $err' ERR

# trailing / would prevent proper pruning in find commands
local_path=/home/$(id -un)/Documents/Projects/Scripts
remote_path=/media/$(id -un)/usb/Projects/Scripts

# https://unix.stackexchange.com/questions/12203/rsync-failed-to-set-permissions-on-error-with-rsync-a-or-p-option/126489
options="--archive --verbose --recursive --update --progress --backup --suffix=`date +'.%Y-%m-%d_%H-%M-%S.bak'` --no-owner --no-group --no-perms"

# for "install" and "update" arguments
source "$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
# help
help_message="  Written to run rsync with options (current date/time is taken, below is example to dsiplay format):
$options
Between two hardcoded in the script paths (see below), both ways (one after another):
$local_path 
$remote_path
  Usage: $script_name \n"
display_help "$help_message$common_help"
# ====== #


# below does not work if many .bak files, so using find for now.
#    if [ -f $local_path/*.bak ]; then mv $local_path/*.bak $local_path/prevs; fi
#    if [ -f $remote_path/*.bak ]; then mv $remote_path/*.bak $remote_path/prevs; fi 
# repeating 1st rsync is needed to propagate back bak files if newer ones were ininially on remote

# man chown.2
# Only a privileged process (Linux: one with the CAP_CHOWN capability) may change the owner of a file.
# therefore use --no-owner, --no-group cause owner change is of uncertain value

do_sync(){
    if [ -d $remote_path ]; then 
        
        # ===== workaround for renaming / moving (run manually make commands before rsync) ===== #
    
        # v 1
        # below two lines result in growing size of files and multiple runs of same mv commands but 
        # as of now I have not deviced a solution for chained sync, 
        # for only two points instead just empty the files with e.g. "> filename" 


        # v 2:
        # no need to add from local to remote as first rsync would copy full file back
        # no need to run commands if file are identical - means rsync was run already
        # `!` is operator, but `=` is part of primary of conditional expression, therefore even as ! is highest precedence, 
        # no need for () (parentheses had to be backslashed \ if needed)
        # btw what is primary?
        # on small files tested that adding lines to one of files results in comm finding those additional lines in spite of:
        # man comm: comm - compare two sorted files line by line
        complex_flag=0 # set to 1 if changes identified from both sync directions
        to_rsync=1 # to process rsync by default
        f_RE=$remote_path/_rename_move.sh
        f_LO=$local_path/_rename_move.sh

        if [ -f $f_RE ]; then
             if [ -f $f_LO ]; then
                # if both exist, -gt greated than, stat --printf="%s" size in bytes
                if [ $(stat --printf="%s" $f_RE) -gt $(stat --printf="%s" $f_LO) ]; then
                    # small file (2nd) is fully contained in the beginning of larger file (maybe test binary mode more efficient)
                    # -1     suppress column 1 (lines unique to FILE1) : man comm
                    if [ -z "$(comm --nocheck-order -3 -1 $f_RE $f_LO)" ]; then
                        # run only additional commands (remote's on local)     
                        cd $local_path         
                        bash -c "$(comm --nocheck-order -3 -2 $f_RE $f_LO)"
                        # overwrite small with larger one                     
                        cp $f_RE $f_LO
                    else complex_flag=1; fi
                # remote smaller than local
                elif [ $(stat --printf="%s" $f_RE) -lt $(stat --printf="%s" $f_LO) ]; then
                    # small file (1nd) is fully contained in the beginning of larger file (maybe test binary mode more efficient)
                    if [ -z "$(comm --nocheck-order -3 -2 $f_RE $f_LO)" ]; then
                        # run only additional commands (local's on remote)
                        cd $remote_path
                        bash -c "$(comm --nocheck-order -3 -1 $f_RE $f_LO)"
                        # overwrite small with larger one                     
                        cp $f_LO $f_RE
                    else complex_flag=1; fi
                # same size but different contents
                elif [ ! $(sha256sum $f_RE | awk '{ print $1 }') = $(sha256sum $f_LO | awk '{ print $1 }') ]; then
                    complex_flag=1;
                fi
                # nothing to do if files are the same
             # if only remote exists                
             else
                cd $local_path && $f_RE
             fi

             # neither file was found to be part of another as a whole
             # expect changes (moves/renames) from both ends
             if [ $complex_flag -eq 1 ]; then

                # doing echo "$()" removes trailing empty lines compared to for some reason (TODO why?)

                # check that doing symmetrically with appending to local results in same number of lines in a file
                # and selecting matching in both and adding distinct from both too results in same number of lines in a file
                cp $f_RE $f_LO.1 && (comm --nocheck-order -3 -1 $f_RE $f_LO) >> $f_LO.1
                cp $f_LO $f_LO.2 && (comm --nocheck-order -3 -2 $f_RE $f_LO) >> $f_LO.2
                (comm --nocheck-order -1 -2 $f_LO $f_RE) > $f_LO.3
                (comm --nocheck-order -3 -1 $f_RE $f_LO) >> $f_LO.3
                (comm --nocheck-order -3 -2 $f_RE $f_LO) >> $f_LO.3
                counts_1="$(wc $f_LO.1 | awk '{ print $1,$2,$3 }')"
                counts_2="$(wc $f_LO.2 | awk '{ print $1,$2,$3 }')"
                counts_3="$(wc $f_LO.3 | awk '{ print $1,$2,$3 }')"
                # same counts, Ok
                if [ $counts_1 = $counts_2 ] && [ $counts_2 = $counts_3 ]; then
                    cd $remote_path 
                    bash -c "$(comm --nocheck-order -3 -1 $f_RE $f_LO)"
                    cd $local_path 
                    bash -c "$(comm --nocheck-order -3 -2 $f_RE $f_LO)"
                    cp $f_LO.3 $f_RE
                    mv $f_LO.3 --force $f_LO
                    rm $f_LO.1 $f_LO.2
                else
                    echo "========= manual intervention might be needed ==========="
                    echo "Results of analysis of $f_LO & $f_RE via [comm] app has not matched;"
                    echo "renaming/moving not performed;"
                    echo "rsync of $local_path & $remote_path not performed; see differences between files:"
                    echo "$f_LO.1, $f_LO.2, $f_LO.3"
                    echo "========================================================="
                    to_rsync=0
                fi
         fi   
        # if only local exists
        elif [ -f $f_LO ]; then
            cd $remote_path && $f_LO
        fi

        # ===== end of workaround ===== #

        if [ $to_rsync -eq 1 ];then
            rsync $options $local_path/ $remote_path
            rsync $options $remote_path/ $local_path
            rsync $options $local_path/ $remote_path
        fi

        # below is to move old versions away 
        find "$local_path" -path "$local_path/prevs" -prune -o -name '*.bak' -exec mv "{}" "$local_path/prevs" \;
        find "$remote_path" -path "$remote_path/prevs" -prune -o -name '*.bak' -exec mv "{}" "$remote_path/prevs" \;

# previous versions, prune works "more correct", forgot why
#        find $local_path -maxdepth 1 -name '*.bak' -exec mv "{}" $local_path/prevs \;
#        find $remote_path -maxdepth 1 -name '*.bak' -exec mv "{}" $remote_path/prevs \;
    else
        echo $remote_path is not available
    fi
}

# adding check that most recent r_sync is run
# the check assumes first set of local/remote point to scripts

# if local path to scripts exists
if [ -d $local_path ]; then 
    sha_active=$(cat `which r_sync`| sha256sum | awk '{ print $1 }')
    sha_local=$(sha256sum $local_path/r_sync.sh | awk '{ print $1 }')
    if [ ! $sha_active = $sha_local ]; then
        echo r_sync code do not match: active vs local, please check, run \"r_sync update\" to update active from local
        # help read : -r : do not allow backslashes to escape any characters  
        # -p prompt	: output the string PROMPT without a trailing newline before attempting to read
        # -n nchars	: return after reading NCHARS characters rather than waiting
    	#   for a newline, but honor a delimiter if fewer than
    	#   NCHARS characters are read before the delimiter  
        read -p "! Run r_sync with currently intalled code anyway (y/n)? " -n 1 -r
        echo    # (optional) move to a new line
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit; fi
    fi
else    
    # for newly installed systems scripts folder I consider might be usedful to have
    mkdir --parents $local_path
    chmod a+rwx $local_path
fi

# if remote path to scripts exists, as maybe only some of folders to be synced on remote
if [ -d $remote_path ]; then 
    sha_remote=$(sha256sum $remote_path/r_sync.sh | awk '{ print $1 }')   
    if [ ! $sha_active = $sha_remote ]; then
        echo r_sync code do not match: active vs remote, please check, if remote is newer and correct, run  \"$remote_path/r_sync.sh install\" to update active from remote 
        # https://stackoverflow.com/questions/1885525/how-do-i-prompt-a-user-for-confirmation-in-bash-script
        read -p "! Run r_sync with currently intalled code anyway (y/n)? " -n 1 -r
        echo    # (optional) move to a new line
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit; fi
    fi
fi

echo "=============START SYNC=================="
do_sync

local_path=/home/$(id -un)/Documents/Projects/C_code
remote_path=/media/$(id -un)/usb/Projects/C_code
do_sync

echo "==============END SYNC==================="

exit

Notes:

#man bash
# file1 -nt file2
#      True if file1 is newer (according to modification date) than file2, or if file1 exists and file2 does not.
# file1 -ot file2
#      True if file1 is older than file2, or if file2 exists and file1 does not.

# man rsync
# A trailing slash on the source changes this behavior to avoid creating an additional directory  level
# at  the destination.  You can think of a trailing / on a source as meaning "copy the contents of this
# directory" as opposed to "copy the directory by name"

How to use hard links, but no hardlinks for folders, see my answers on unix SE

https://lincolnloop.com/blog/detecting-file-moves-renames-rsync/


rsync --archive --hard-links --progress --verbose 1/1 2

cp --recursive --link --preserve=mode,ownership,timestamps 1 1-work


rsync --archive --hard-links --progress --verbose --no-inc-recursive 1/1 1/1-work 2
--dry-run 
Notes:

    As an rsync expert you are surely aware that slashes at the end of the rsync paths have strict meaning. If not, consult the manpage.
    You may want to run it with the safety -n switch first to see what would happen. You will see =&gt;’s to mark the hard-linking.


1: rename inside.txt->inside.1
2: rename init.txt->init.2


