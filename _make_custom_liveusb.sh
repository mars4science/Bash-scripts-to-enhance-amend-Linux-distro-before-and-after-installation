#!/bin/bash

# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; sleep 10; exit $err' ERR

# ---- auto script  ----- #
# ---- manual way is after auto script (note: manual outdated, auto up-to-date)  ----- #

# Note 1: script produced errors when run from location in path containing spaces, not all variables are fully quoted in scripts (TODO)
# Note 2: Creating ISO files larger than 4Gb needs `mksquashfs` supporting `-no-strip` option, LM 21 has it.
# Note 3: It's been noted `unmkinitramfs` somehow does not work correcty if scripts are run on a system based on distro different from the one of original ISO file (noted for LM 21 / 20), it affects changing initramfs (functionality can be turned on/off via change_initramfs control variable).

# ---- parameters ---- #
distro_label="GNU-Linux_1.64_b21" # max 32 symbols as used for ISO volume ID (volume name or label) (`man genisoimage`), maybe some other rules apply

software_path_root=/media/ramdisk/LM # the script is written to look for software to take from there
original_iso="${software_path_root}"/linuxmint-21-cinnamon-64bit.iso # the script is written to look there for original ISO

work_path=/media/ramdisk/work # the script is written to create temporary files and resulting ISO there (free space "expected")
change_boot_menu="true" # set to "true" to edit boot menu (which adds options e.g. boot to ram, change id of live user, add rights for virt manager usage)
new_legacy_menu_title="GNU/Linux Cinnamon OS based on LM 21 64-bit (legacy boot)"

change_initramfs="true" # set to true to change early boot envinonment, now changing of user name is programmed
user_name="user1" # in case of change_initramfs=true put arbitrary name to set for user, in case of "false" put user name as set in the distro (used in run_at_boot_liveusb.sh - custom init script and systemd_to_run_as_user.sh - run as user during boot)

# array, list separated by space; correct syntax of each entry can be found in /etc/locale.gen (languagecode_COUNTRYCODE); used to generate locales, set keyboard layouts available for switching
locales=("fr_FR" "en_US" "de_DE") # first in array also used to set system interface language; set to empty () for not doing locales changes (so for liveISO layouts will be default - Eng only, as layouts are set via amended to that setting script during boot time)

# as after_original_distro_install.sh to be run in chrooted environment there is code to map (via mount) software_path_root to  path_to_software_in_chroot - where above mentioned script is written to look for software
path_to_software_in_chroot="/tmp/path_for_mount_to_add_software_to_liveiso"
liveiso_path_scripts_in_chroot=/usr/local/bin/amendedliveiso-scripts-etc
liveiso_path_settings_in_chroot=/usr/share/amendedliveiso-settings
liveiso_sources_in_chroot=/usr/src/amendedliveiso # to copy all scripts to have sources on resulting ISO
work_path_in_chroot=/tmp # used by apt_get.sh
use_cgroup='true' # to limit CPU usage during CPU intensive tasks of long duration (chroot, mksquashfs)
cgroup="gr1"
cpu_max_chroot="500000 1000000" # limit for whole CPU, write quota and period (valid values in the range of 1000 to 1000000) in microseconds, for  performance reasons could be better to use larger periods). Total CPU time in the system equals period multiplied by number of cores/processors
cpu_max_mksquashfs="1500000 1000000"
limit_sq_total=12; limit_sq_usr_lib=10; limit_sq_total_sans_usr_lib=7 # limits in Gb of sizes to compress into squashfs, if above split into more squashfs files

# ---- parameters end ---- #

if [ ! -e "$original_iso" ]; then delay=5; echo original iso file not found at $original_iso, ending script in $delay seconds; sleep $delay; exit 1; fi

script_path="$(dirname "$(realpath "$0")")"

if [ "${use_cgroup}" = 'true' ]; then
    sudo cgcreate -g cpu,cpuset:"${cgroup}" # no error noted if this cgroup already exists
    sudo cgset -r cpu.max="${cpu_max_chroot}" "${cgroup}"
    sudo cgset -r cpuset.cpus="0-1" "${cgroup}"
    printf "Next line moves to cgroup ${cgroup} this process, id of the process: "
    echo $$ | sudo tee /sys/fs/cgroup/"${cgroup}"/cgroup.procs
fi

# commands that make amendments that result in changed booted live system
change_squash() {

    # remove need to press ENTER at shutdown
    sudo perl -i -pe 's/prompt=1/prompt=/' $work_path/fin_sq/usr/sbin/casper-stop

    # for reference when running to know the build version
    echo "AMENDED_ISO_LABEL=$distro_label" | sudo tee --append $work_path/fin_sq/etc/os-release > /dev/null

    # copy user specific scripts to be run later (later some [maybe all except dconf_config as maybe it requires systemd running] expected to be moved to initrd change in change_boot() function)

    scripts_to_copy_to="$work_path/fin_sq"$liveiso_path_scripts_in_chroot
    settings_to_copy_to="$work_path/fin_sq"$liveiso_path_settings_in_chroot

    if [ -e $scripts_to_copy_to ]; then
        echo "  WARNING: path for scripts to run during liveISO boot exists, suspect possible collision, removing scripts there..."
        sudo rm --force "${scripts_to_copy_to}"/*.sh
#        echo path for scripts exists, suspect possible collision. exiting...
#        echo run script again and type d to delete contents within working files, then Ctrl-C when asked for interactive
#        exit 1
    else
        sudo mkdir $scripts_to_copy_to
    fi
    if [ -e $settings_to_copy_to ]; then
        echo "  WARNING: path for settings exists, suspect possible collision..."
#        echo run script again and type d to delete contents within working files, then Ctrl-C when asked for interactive
#        exit 1
    else
        sudo mkdir $settings_to_copy_to
    fi

    sudo cp $script_path/to_iso_to_run_once_liveiso_boot/* $scripts_to_copy_to
    for f in ${scripts_to_copy_to}/*.sh ; do
        sudo sed --in-place --regexp-extended -- "s|liveiso_path_scripts_root|$liveiso_path_scripts_in_chroot|" "$f"
        sudo sed --in-place --regexp-extended -- "s|liveiso_path_settings_root|$liveiso_path_settings_in_chroot|" "$f"
        if [ "${change_initramfs}"="true" ]; then
            sudo sed --in-place --regexp-extended -- "s|user=mint|user=${user_name}|" "$f" # systemd_to_run_as_user.sh, run_at_boot_liveusb.sh
            # sudo sed --in-place --regexp-extended -- "s/user_name=mint/user_name=$user_name/" "$f"
        fi
    done

    # copy sources of scripts to ISO
    scripts_sources_to_copy_to="$work_path/fin_sq"$liveiso_sources_in_chroot/scripts-for-amendeding-iso
    sudo mkdir --parents $scripts_sources_to_copy_to
    sudo rsync -rlptD --filter='exclude .*' $script_path/* $scripts_sources_to_copy_to

    # original apt and dpkg states before amendment with other deb packages
    sudo rsync -rlptD --filter='exclude .*' $software_path_root/apt_dpkg_state "$work_path/fin_sq"$liveiso_sources_in_chroot

    # sudo cp --recursive "${software_path_root}"/settings/* $settings_to_copy_to
    sudo rsync -rlptD "${software_path_root}"/settings/ $settings_to_copy_to # replaced cp because IIRecalledC * expansion does not include dot prefixed files

    sudo rsync -rlptD --omit-dir-times "${software_path_root}"/to_root/ "$work_path/fin_sq" # copy what needs to be copied additionally to appropriate places along with paths

   sudo rsync -rlptD --omit-dir-times "${software_path_root}"/to_iso_root/ "$work_path/fin" # copy to location to be available in /cdrom after boot

    # in case debs are not installed right at this script run time copy stopfan to be able to turn fan off after ISO boot
    sudo cp "${software_path_root}"/bin/stopfan $work_path/fin_sq/usr/local/bin
    sudo chmod +xs $work_path/fin_sq/usr/local/bin/stopfan

    # to install debs and other files need to have path to them inside chrooted environment
    # see https://unix.stackexchange.com/questions/683439/mount-twice-bind-why-some-parameters-change-others-not
    sudo mount -o bind,x-mount.mkdir "${software_path_root}" $work_path/fin_sq"${path_to_software_in_chroot}"
    sudo mount -o bind,remount,ro "${software_path_root}" $work_path/fin_sq"${path_to_software_in_chroot}"

    # to run script(s) via chroot need path to them inside chrooted environment
    sudo mount -o bind,x-mount.mkdir $script_path $work_path/fin_sq/media/root/Scripts
    sudo mount -o bind,remount,ro $script_path $work_path/fin_sq/media/root/Scripts

    # moved here from after_original_distro_install.sh as I understood is customary to set chroot environment before calling chroot
    sudo mount -t proc proc $work_path/fin_sq/proc
    sudo mount -t sysfs sys $work_path/fin_sq/sys
    sudo mount -t devtmpfs devtmpfs $work_path/fin_sq/dev # when contents of /dev had been partly deleted, [3] helped
    sudo mount -t devpts devpts $work_path/fin_sq/dev/pts
    # note which looks as made before `mount /proc` was added: # mount  ----- output: mount: failed to read mtab: No such file or directory

    locales=$(echo "${locales[@]@A}" | sed "s/"\""/'/g") # A operator of bash generate declare line with double quotes, need to replace for bash -c below
    sudo chroot $work_path/fin_sq /bin/bash -c "\
        export software_path_root=${path_to_software_in_chroot}; \
        export liveiso_path_scripts_root=${liveiso_path_scripts_in_chroot}; \
        export locales="\""${locales}"\"";\
        export liveiso_path_sources_root="${liveiso_sources_in_chroot}"; \
        export work_path=${work_path_in_chroot}; \
        /media/root/Scripts/after_original_distro_install.sh"
    if [ $? -ne 0 ]; then echo "=== That code has been written to display in case of non zero exit code of chroot of after_original_distro_install.sh ==="; fi
}

# commands that amend boot menus and options
change_boot() {

    # modify boot config
    # sed usage see [2]

    # substitute init to change id of live user, etc. (check if it was copied to ISO)
    if [ -e "$scripts_to_copy_to/run_at_boot_liveusb.sh" ] ; then
        custom_init_boot_option="init=$liveiso_path_scripts_in_chroot/run_at_boot_liveusb.sh "
    else custom_init_boot_option=""; fi

    # added after studying casper script in initramfs (initrd file):
    # "showmounts" added for adding /casper with nounts to /cow that is mounted over by init/casper of initramfs (if change_initramfs set to "true")
    # "nopersistence" is for not creating writable partition on USB stick to store logs

    # ======= for UEFI boot =======

    grub_config=$work_path/fin/boot/grub/grub.cfg

    # 	linux	/casper/vmlinuz  file=/cdrom/preseed/linuxmint.seed boot=casper iso-scan/filename=${iso_path} toram --
    # duplicate first menu entry three times, \s\S needed as in perl . (dot) does not include end of line
    perl -0777e 'while(<>){s/(menuentry[\s\S]*?\n\}\n)/\1\1\1\1/;print "$_"}' ${grub_config} | 1>/dev/null sudo tee ${grub_config}_tmp
    sudo mv --force ${grub_config}_tmp ${grub_config}

    # change first manu entry to boot to ram, add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| rfkill.default_state=0 showmounts toram ${custom_init_boot_option}--|" ${grub_config}
    sudo sed --in-place --regexp-extended -- '0,/64-bit"/s//64-bit to RAM, verbose (UEFI: all menu entries)"/' ${grub_config}
    # change second manu entry to make text mode boot, add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| rfkill.default_state=0 showmounts nopersistent level 3 ${custom_init_boot_option}--|" ${grub_config}
    sudo sed --in-place --regexp-extended -- '0,/64-bit"/s//64-bit, text mode, verbose"/' ${grub_config}
    # change third manu entry to add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| rfkill.default_state=0 showmounts nopersistent ${custom_init_boot_option}--|" ${grub_config}
    sudo sed --in-place --regexp-extended -- '0,/64-bit"/s//64-bit, verbose"/' ${grub_config}
    # change forth menu entry to add custom init script, 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| quiet splash ${custom_init_boot_option}--|" ${grub_config}
    sudo sed --in-place --regexp-extended -- '0,/64-bit"/s//64-bit, quiet"/' ${grub_config}
    # add timeout to start first meny entry automatically (for some reason default script cfg does not have it)
    echo | sudo tee --append ${grub_config} > /dev/null
    echo "set timeout_style=menu" | sudo tee --append ${grub_config} > /dev/null
#    echo 'if [ "${timeout}" = 0 ]; then' | sudo tee --append ${grub_config} > /dev/null
    echo "set timeout=5" | sudo tee --append ${grub_config} > /dev/null
#    echo "fi" | sudo tee --append ${grub_config} > /dev/null

    # to made text large on hiDPI displays and to improve cursor/manual boot optopns editing speed at boot time
    echo "GRUB_GFXMODE=640x480x32,auto" | sudo tee --append ${grub_config} > /dev/null

    # remove trademark info from boot menu
    sudo sed --in-place --regexp-extended -- 's/Linux Mint.*Cinnamon/OS/' ${grub_config}


    # ======= for legacy boot =======

    legacy_config=$work_path/fin/isolinux/isolinux.cfg

    #   append  file=/cdrom/preseed/linuxmint.seed boot=casper initrd=/casper/initrd.lz toram --
    # edit menu title
    sudo sed --in-place -- "s|\(menu title \).*|\1${new_legacy_menu_title}|" ${legacy_config}
    # duplicate first menu entry two times, \s\S needed as in perl . does not include end of line   
    perl -0777e 'while(<>){s/(label[\s\S]*?--\n)(menu default\n)/\1\2\1\1\1/;print "$_"}' ${legacy_config} | 1>/dev/null sudo tee ${legacy_config}_tmp
    sudo mv --force ${legacy_config}_tmp ${legacy_config}
    # edit in-place, add three more rows number of rows in the menu
    sudo perl -i -pe 's/(MENU ROWS )([0-9]+)/$1.($2+3)/e' ${legacy_config}
    sudo perl -i -pe 's/(TABMSGROW )([0-9]+)/$1.($2+3)/e' ${legacy_config}
    sudo perl -i -pe 's/(CMDLINEROW )([0-9]+)/$1.($2+3)/e' ${legacy_config}

    # change first manu entry to boot to ram, add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- '0,/label.*/s//label ram/' ${legacy_config}
    sudo sed --in-place --regexp-extended -- '0,/( *menu label.*Mint)$/s//\1 (to RAM, verbose)/' ${legacy_config}
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| rfkill.default_state=0 showmounts toram ${custom_init_boot_option}--|" ${legacy_config}
    # change second manu entry to add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- '0,/label.*/s//label text/' ${legacy_config}
    sudo sed --in-place --regexp-extended -- '0,/( *menu label.*Mint)$/s//\1 (text mode, verbose)/' ${legacy_config}
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| rfkill.default_state=0 showmounts nopersistent level 3 ${custom_init_boot_option}--|" ${legacy_config}
    # change third manu entry to add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- '0,/label.*/s//label verbose/' ${legacy_config}
    sudo sed --in-place --regexp-extended -- '0,/( *menu label.*Mint)$/s//\1 (verbose)/' ${legacy_config}
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| rfkill.default_state=0 showmounts nopersistent ${custom_init_boot_option}--|" ${legacy_config}
    # change forth menu entry to add custom init script, 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| quiet splash ${custom_init_boot_option}--|" ${legacy_config}
    sudo sed --in-place --regexp-extended -- '0,/( *menu label.*Mint)$/s//\1 (quiet)/' ${legacy_config}
    # edit timeout
    sudo sed --in-place -- 's/\(timeout\).*/\1 50/' ${legacy_config}

    # remove trademark info from boot menu
    sudo sed --in-place --regexp-extended -- 's/Linux Mint/OS/' ${legacy_config}

    # replace menu background; 640x480 png was displayed, 715x480 was NOT displayed at boot time
    if [ -e "${software_path_root}/splash.png" ] ; then
        sudo cp --force "${software_path_root}/splash.png" "$work_path/fin/isolinux/splash.png" ; fi

    # code to repalce memtest to start with stock iso
    sudo cp "${software_path_root}/memtest86+/memtest86+-5.31b.bin" $work_path/fin/casper/memtest
}


change_initrd(){

    initrd_path=$work_path/fin/casper/initrd.lz

    # unpack
    sudo unmkinitramfs $initrd_path $work_path/initrd

    # amend
    sudo sed --in-place --regexp-extended -- "s|USERNAME=.*|USERNAME="\""$user_name"\""|" $work_path/initrd/main/etc/casper.conf
    sudo sed --in-place --regexp-extended -- "s|USERFULLNAME=.*|USERFULLNAME="\""User $user_name"\""|" $work_path/initrd/main/etc/casper.conf

    # add mount of /cow of initramfs to /casper of resultant fs
    sudo sed --in-place --regexp-extended -- 's|(if [[] -n "[$][{]SHOWMOUNTS[}]" []]; then)|\1\n\n        mkdir -p "${rootmnt}/${LIVE_MEDIA_PATH}/cow"\n        mount --bind /cow "${rootmnt}/${LIVE_MEDIA_PATH}/cow"\n|' $work_path/initrd/main/scripts/casper

    # change mount option for e.g. squashfs files as "-o move" results in empty folder
    sudo sed --in-place --regexp-extended -- 's|(mount )-o move( "[$][{]d[}]" "[$][{]rootmnt[}]/[$][{]LIVE_MEDIA_PATH[}]/[$][{]d[#][#][*]/[}]")|\1--bind\2|' $work_path/initrd/main/scripts/casper

}

# ??? where and what for this comment near initrd??? Clear out debconf database again to avoid confusing ubiquity later.

u_mount(){
    # proc path exists before script, mount_path is relative, so grep, not just `findmnt "$mount_path"` and current folder is "expected" to be $work_path
    # no need to escape " inside command substitution as double quotes preserve literal meaning of qouble quotes (man bash: search for "QUOTING")
    mount_point="${1//\/\//\/}" # remove extra '/' just in case work_path ends with '/' for grep to find a match
    if [ -n "$(findmnt | grep "${mount_point}" | head -n 1)" ]; then
        sudo umount "${mount_point}" # `head -n` as a "just in case" safeguard against using several lines for '-n' of `if`, works w/out it
        if [ $? -ne 0 ]; then
            delay=10; echo "  ERROR: Unmounting ${mount_point} unsuccessful (per return code); this script is written to end in $delay seconds"; sleep $delay; exit 1;
        fi
    fi
}

un_mount_in_squashfs(){
    u_mount "${work_path}"/fin_sq/dev/pts
    u_mount "${work_path}"/fin_sq/dev
    u_mount "${work_path}"/fin_sq/proc
    u_mount "${work_path}"/fin_sq/sys
    u_mount "${work_path}"/fin_sq/media/ramdisk
    u_mount "${work_path}"/fin_sq/"${path_to_software_in_chroot}"
    u_mount "${work_path}"/fin_sq/media/root/Scripts
}

un_mount_in_work_path(){
    u_mount "${work_path}"/fin_sq
    u_mount "${work_path}"/fin
    u_mount "${work_path}"/iso_sq
    u_mount "${work_path}"/iso
}

un_mount(){
    un_mount_in_squashfs
    un_mount_in_work_path
}

# the rest is coded to work "universally" (w/out per distro modifications)

# x ("x") not needed because with "" strings are not empty, if first expression is not true, second is not evaluated IIRC
# TODO add "" around $work_path on next line
if [ -e "$work_path" ] && [ "$(ls $work_path)" != "" ]; then
    # https://stackoverflow.com/questions/1885525/how-do-i-prompt-a-user-for-confirmation-in-bash-script
    read -p "! $work_path exists and not empty, abort (n), proceed (y), try deleting contents within it (d)? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[YyDd]$ ]]; then exit; fi
    if [[ $REPLY =~ ^[Dd]$ ]]; then
        cd "$work_path"
        un_mount
        sudo rm -R $work_path/*
        Eval=$?
        if [ $Eval -ne 0 ]; then
            delay=10; echo "  ERROR: Deleting contents of ${work_path} unsuccessful (per return code); this script is written to end in $delay seconds"; sleep $delay; exit 1;
        fi
            delay=1; echo "Deleting contents of ${work_path} successful (per return code); this script is written to continue in $delay second(s)"; sleep $delay;
    fi    
else
    mkdir --parents $work_path && cd $_
fi

echo
echo "Choose mode:"
echo "'i' key (interactive) to pause after installation/change of everything but before starting to pack them into new ISO and also try to preserve all work files intact (run the script again to delete)"
echo "'d' key (delete) to pause as for 'i' but detele working files along the way leaving only amended iso file"
echo "'r' key (result) NOT to pause and also delete work files leaving only amended ISO file without pausing for user input"
read -p "'p' (preserve) NOT to pause but preserve work files (run the script again to delete):" -n 1 -r
echo  # (optional) move to a new line
if [[ $REPLY =~ ^[Ii]$ ]]; then
    interactive_mode="true";
    delete_work_files_without_user_interaction="false";
elif [[ $REPLY =~ ^[Dd]$ ]]; then
    interactive_mode="true";
    delete_work_files_without_user_interaction="true";
elif [[ $REPLY =~ ^[Rr]$ ]]; then
    interactive_mode="false";
    delete_work_files_without_user_interaction="true";
elif [[ $REPLY =~ ^[Pp]$ ]]; then
    interactive_mode="false";
    delete_work_files_without_user_interaction="false";
else
    echo '  ERROR: invalid input, terminating...'
    exit 1
fi

mkdir iso to temp fin initrd

# man mount: The mount command automatically creates a loop device from a regular file if a  filesystem  type  is
#            not specified or the filesystem is known for libblkid
# if original_iso is located on read-write mount, then mount command is expected to output a WARNING about device being write-protected; if read-only - no output expected.
# makes sense : if ro, then probably user knows about write-protection already.
sudo mount $original_iso iso #  -o loop

# TODO: check: maybe graft parameter of genisoimage can be used instead of overlayfs to amend mounted original iso contents
sudo mount -t overlay -o lowerdir=iso,upperdir=to,workdir=temp overlay fin

# mount squashfs for modification
mkdir iso_sq to_sq temp_sq fin_sq
sudo mount iso/casper/filesystem.squashfs iso_sq -t squashfs -o loop
sudo mount -t overlay -o lowerdir=iso_sq,upperdir=to_sq,workdir=temp_sq overlay fin_sq

# --- now modify squashfs ---
# Now can modify/add/delete files/folders in either "to" or "fin" folders.
# Changes to them are "mirrored".  
# To undo deletion of original file delete "deleted" file from "to" with `sudo rm path/file`.  
# Do not delete auto created folders in e.g. "to" as for some reason files in that folder would become "unvisible" in overlayfs resulting folder, asked a question:
# https://unix.stackexchange.com/questions/679391/unionfs-deleting-folder-from-upperdir-results-in-diappearance-of-files-in-the-o
# If deleted anyway, fixing maybe by overlayfs `mount -o remount` 

# call two main functions
change_squash
if [ "${change_boot_menu}" = "true" ] ; then change_boot; fi
if [ "${change_initramfs}" = "true" ] ; then change_initrd; fi

if [ "$interactive_mode" = "true" ]; then
    echo "  Next in addition to now hardcoded changes one can modify system in $work_path/fin for boot menus, $work_path/initrd for early boot environment and in $work_path/fin_sq for resulting live system."
    echo "  now code to invoke bash in chrooted environment; type "\""exit"\"" to continue the srcipt and build new iso"
    sudo chroot $work_path/fin_sq
fi

if [ "${change_initramfs}" = "true" ] ; then

    echo "  repacking initrd ..."
    sudo rm $initrd_path; sudo touch $initrd_path

    # to make resultant file reproducible
    # --reproducible requires cpio >= 2.12
    if [ "x${SOURCE_DATE_EPOCH}"="x" ]; then SOURCE_DATE_EPOCH=$(date "+%F")" 00:00:00" ; fi # SOURCE_DATE_EPOCH="Dec 31 00:00:00 UTC 2022" ;fi
    # ensure that no timestamps are newer than $SOURCE_DATE_EPOCH
    find "$work_path/initrd" -newermt "${SOURCE_DATE_EPOCH}" -print0 | \
	    sudo xargs -0r touch --no-dereference --date="${SOURCE_DATE_EPOCH}"
    
    # now process folders as unmkinitramfs script code as understood and watched makes them

    if [ -d $work_path/initrd/early ]; then
        echo "    ...next firmware from early"
        cd $work_path/initrd/early
        find . -print0 | cpio --null --create --reproducible --format=newc | 1>/dev/null sudo tee --append $initrd_path
    fi

    for (( i=2 ; i<10 ; i++ )) ; do
        if [ -d $work_path/initrd/early${i} ]; then
            echo "    ...next firmware from early${i}"
            cd $work_path/initrd/early${i}
            find . -print0 | cpio --null --create --reproducible --format=newc | 1>/dev/null sudo tee --append $initrd_path
        else break; fi
    done

    echo "    ...next main FS"
    cd $work_path/initrd/main
    find . -print0 | cpio --null --create --reproducible --format=newc | xz --format=lzma | 1>/dev/null sudo tee --append $initrd_path
    echo "  ... repacking initrd code was before this line."
    cd $work_path
fi

if [ "${use_cgroup}" = 'true' ]; then
    sudo cgset -r cpu.max="${cpu_max_mksquashfs}" "${cgroup}"
    sudo cgset -r cpuset.cpus="all" "${cgroup}"
fi

# --- START of squashfs ---

# Note: mksquashfs operation takes a lot of memory; in localities where memory seems a bit not enough to produce final result one is advised to try to lower limits (in 'if' statements) to split file system even further and split to smaller pieces

un_mount_in_squashfs # if not unmounted adds e.g. /proc, which I think it not how liveUSB is made to work and it would make it less properly working
echo "Time now is: $(date -Isec)"
echo   Disk usage in MiB:
du --block-size=1M --threshold=1 --total --summarize fin_sq/* 2>/dev/null
echo
sudo rm fin/casper/filesystem.squashfs # remove original for if [ ! -e ]

if [ $(2>/dev/null du --summarize --block-size=1G "fin_sq" | tail --lines=1 | awk '{print $1}') -le ${limit_sq_total} ]; then # maximum size is "rule of thumb" (to be finetuned, to get 4G max, based on past observations of ~34% in mksquashfs output for /usr/lib, ~40% for the rest) to estimate whether to attempt to fit all fs into one squashfs file (mksquashfs is by far the longest by time part of the script, so attempting to save time); `tail` added just in case
    time sudo mksquashfs fin_sq fin/casper/filesystem.squashfs -noappend -b 32768 -comp zstd -Xcompression-level 22 # was? '-comp xz'; adding option '-processors 1' did NOT help much to solve issue of `mksquashfs` using resident menory in the size of ~3Gb (a lot, about size of file to be created by the command)

# if larger than 4Gb, split system to two squashfs files (casper scripts of Linux Mint support that); usr/lib by experince is about half
    if [ $(stat --format='%s' fin/casper/filesystem.squashfs) -ge 4294967296 ]; then # AFAIK exect limit for squashfs file to be functioning properly
        sudo rm fin/casper/filesystem.squashfs
    fi
fi

if [ ! -e fin/casper/filesystem.squashfs ]; then
    # Below split to two files was initially implemented as moves of folders, however moves in overlay seems to take memory, also learned there is -no-strip option added in 2021 and of -e option usage from README (both are absent from man page, but present in output of mksquashfs to standard error if run e.g. w/out arguments)
    cd fin_sq # for -no-strip option
    # if even /usr/lib might be too large (estimated squashfs size ~34% of uncompressed) - split in two
    # as there are no redos in case of too large size here as opposed to one squashfs initial try, compare to less than 4Gb*3 to increase chances to be on the safe side (du seems to round up)
    if [ $(2>/dev/null du --summarize --block-size=1G "usr/lib" | tail --lines=1 | awk '{print $1}') -gt ${limit_sq_usr_lib} ]; then
        time sudo mksquashfs usr/lib/x86_64-linux-gnu ../fin/casper/filesystem_usr-lib-x86_64-linux-gnu.squashfs -noappend -b 32768 -comp zstd -Xcompression-level 22 -no-strip

        if [ "${delete_work_files_without_user_interaction}" = "true" ]; then
            sudo rm --recursive usr/lib/x86_64-linux-gnu/*; fi # delete no longer needed files to free memory
        ex_flag='-e'; ex_argument="x86_64-linux-gnu" # argument for exclude (-e) does not include leading directories (found out by try-and-error)
    fi

    time sudo mksquashfs usr/lib ../fin/casper/filesystem_usr-lib.squashfs -noappend -b 32768 -comp zstd -Xcompression-level 22 -no-strip ${ex_flag} ${ex_argument} # as e_* not quoted if not set will not be additional arguments

    if [ "${delete_work_files_without_user_interaction}" = "true" ]; then
        sudo rm --recursive usr/lib/*; fi # delete no longer needed files to free memory

    # if even sans /usr/lib estimated size might be too large, (estimated squashfs size ~40% of uncompressed)
    # bash's arithmetic expression seems to round down
    if [ $((($(2>/dev/null du --summarize --block-size=1M "." | tail --lines=1 | awk '{print $1}')-$(2>/dev/null du --summarize --block-size=1M "usr/lib" | tail --lines=1 | awk '{print $1}'))/1024)) -gt ${limit_sq_total_sans_usr_lib} ]; then
        time sudo mksquashfs usr/share ../fin/casper/filesystem_usr-share.squashfs -noappend -b 32768 -comp zstd -Xcompression-level 22 -no-strip

        if [ "${delete_work_files_without_user_interaction}" = "true" ]; then
            sudo rm --recursive usr/share/*; fi # delete no longer needed files to free memory
        es_flag='-e'; es_argument="usr/share"
    fi

    cd ..
    time sudo mksquashfs fin_sq fin/casper/filesystem.squashfs -noappend -b 32768 -comp zstd -Xcompression-level 22 -e "usr/lib" ${es_flag} ${es_argument} # as e_* not quoted if not set will not be additional arguments

fi
# --- END of squashfs ---

# --- generate new iso image ---

# check if enough memory is still available for the image
# fs_size=0; for f in fin/casper/*.squashfs ; do fs_size=$(( fs_size + $(stat --printf="%s" $f)/1048576 )) ; done # previous code
fs_size=$(2>/dev/null du --summarize --block-size=1M fin | tail --lines=1 | awk '{print $1}')

# for tmpfs `df` can show more available space than available RAM, hence second check in the function
check_free_memory(){
    fs_type=$(df --print-type "${work_path}" | tail -1 | awk '{print $2}')
    fs_free_memory=$(df --block-size=1048576 "${work_path}" | tail -1 | awk '{print $4}')
    if [ $(( fs_free_memory - fs_size*11/10 )) -le 200 ]; then
        false
    elif [ ${fs_type}="tmpfs" ] && [ $(( $(free -wm | awk '/^Mem:/ { print $8 }') - fs_size*11/10 )) -le 200 ]; then
        false
    else
        true
    fi
}

check_free_memory
if [ $? -ne 0 ]; then
    echo "Available memory is less than [110% of size of all file(s) for ISO + 200 MB], might need more memory to complete iso file creation"
    if [ "${delete_work_files_without_user_interaction}" = "false" ]; then
        echo "Press (y/Y) to delete working files in $work_path/fin_sq that made up squashfs filesystem file(s)"
        read -p "Any other key to open sub-shell to pause and maybe add more free memory manually"  -n 1 -r
        echo  # (optional) move to a new line
    fi
    if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
        echo "  Next deleting working files in $work_path/fin_sq that made up squashfs filesystem file(s)"
        un_mount_in_squashfs
        sudo rm -R fin_sq/*
    else
        echo "Type "\""exit"\"" then press "\""Enter"\"" to continue the script"
        bash -i
    fi
fi

check_free_memory
if [ $? -ne 0 ]; then
    echo "After deleting files available memory is still less than [110% of size of all file(s) for ISO + 200 MB], might need more memory to complete iso file creation"
# TODO if [ "$interactive_mode" = "true" ]; then
    echo "Press (a/A) to abort script after deleting all files in $work_path"
    read -p "Any other key to open sub-shell to pause and try to add more free memory manually"  -n 1 -r
    echo  # (optional) move to a new line
    if [[ $REPLY =~ ^[Aa]$ ]]; then
        un_mount_in_work_path
        sudo rm -R $work_path/*
        Eval=$?
        delay=0
        if [ $Eval -ne 0 ]; then
            echo "Deleting contents unsuccessful (per return code);this script is written to end in $delay seconds"; sleep $delay; exit 1;
        fi
        echo "Deleting contents successful (per return code); this script is written to continue in $delay second(s)"; sleep $delay; exit 2;
    else
        echo "Type "\""exit"\"" then press "\""Enter"\"" to continue the script"
        bash -i
    fi
fi

set -x # -x  Print commands and their arguments as they are executed
# added -allow-limited-size for squashfs file size > 2GB 
# omitting `-eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot` resulted in USB able to boot in legacy mode only
# -quiet removed all output, not only progress, but totals too; so use grep
2>&1 sudo genisoimage -allow-limited-size -lJr -o "$distro_label.iso" -V "$distro_label" -b isolinux/isolinux.bin -c isolinux/boot.cat \
-no-emul-boot -boot-load-size 4 --boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot fin | grep --invert-match "done, estimate finish"
sudo isohybrid --uefi "$distro_label.iso"
set +x
# not can write to USB stick, was tested to boot both legacy and EFI
# may check via below, should output like "DOS/MBR boot sector; partition 2 : ID=0xef, start-CHS (0x3ff,254,63), end-CHS (0x3ff,254,63), startsector 640, 7936 sectors"
echo -e "\nNewly created distro hybrid iso file:"
file $"$work_path/$distro_label.iso"

if [ "${delete_work_files_without_user_interaction}" = 'false' ];  then
    echo "Next line is coded to invoke new bash instance; on exit all work files are coded to be removed, only iso file left"
    bash -i
fi

# now delete intermediary data
un_mount # was un_mount_in_work_path, I still do not understand why the result after next rm -R is same - all deleted
sudo rm -R iso to temp fin iso_sq fin_sq temp_sq to_sq initrd
echo "This line is after code to delete working files"
sudo chmod a+rw $"$work_path/$distro_label.iso"

# to leave terminal open with interactive bash if started from GUI
# ps output list processes' paths as called (relative), so use "$0" 
ps --sort +pid -eo pid,stat,command | grep "$0" | head -1 | awk '{print $2}' | grep "s" > /dev/null # man ps : s    is a session leader
if [ $? -eq 0 ]; then bash -i; fi

exit


-----"<Footnotes>"-----

[1]
# testing generating CD (not USB) image:
sudo genisoimage -lJr -o new_custom.iso -V LinuxMint_CD -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 --boot-info-table fin

[2]
# https://stackoverflow.com/questions/148451/how-to-use-sed-to-replace-only-the-first-occurrence-in-a-file

[3]
# From https://tldp.org/LDP/lfs/LFS-BOOK-6.1.1-HTML/chapter06/devices.html "Linux From Scratch - Version 6.1.1, 6.8. Populating /dev"
mknod -m 666 /dev/null c 1 3 # to restore ability to start GUI applications
mknod -m 666 /dev/ptmx c 5 2 # additionally needed to restore ability to open new terminal windows
mknod -m 660 /dev/loop-control c 10 237 # ?
for((i=0;i<=7;i++)); do sudo mknod -m 660 /dev/loop$i b 7 $i; done # to how ability to mount e.g. ISO files. TODO: How many are needed to be made? even with loop-control no devices at all resulted in error
ln -sv /proc/self/fd /dev/fd # to restore ability to use e.g. redirection of output from subshells (e.g. some packages failed to be installed w/out /dev/fd)
# apt-get install tp-smapi-dkms
# /usr/sbin/dkms: line 2106: /dev/fd/63: No such file or directory
# to test:
echo <(echo a)
/dev/fd/63
cat <(echo a) # without /dev/fd that line IIRC produced an error, not 'a'
a




# ----- manual way ----- #

# safety exit if run by clicking
echo list of commands that were made to be copied from the file to CLI (terminal)
sleep 10
exit

# ------ instruction how to amend ISO liveusb of modern Linux distros, tested on Linux Mint 20.2 -----

cd /media/ramdrive

mkdir iso to temp fin 

sudo mount original.iso iso 


# --- that part instead of above one mount line if want to see all parts of ISO
  sudo losetup --partscan --show --find original.iso

  # efi to see contents just in case, no difference to result as of now 2021/11/29
  mkdir efi

  # if output of previous loop0
  sudo mount /dev/loop0p1 iso
  sudo mount /dev/loop0p2 efi

  # to make image for efi, then found out it is already present in `grub` folder.
  sudo dd if=/dev/loop0p2 fin/EFI/BOOT/usb.efi
# --- end of part


# maybe graft parameter of genisoimage can be used instead of overlayfs to amend mounted original iso contents
sudo mount -t overlay -o lowerdir=iso,upperdir=to,workdir=temp overlay fin

# --- now modify squashfs ---

mkdir iso_sq to_sq temp_sq fin_sq
sudo mount iso/casper/filesystem.squashfs iso_sq -t squashfs -o loop
sudo mount -t overlay -o lowerdir=iso_sq,upperdir=to_sq,workdir=temp_sq overlay fin_sq

# Now can modify/add/delete files/folders in either "to" or "fin" folders.
# Changes to them are "mirrored".  
# To undo deletion of original file delete "deleted" file from "to" with `sudo rm path/file`.  
# Do not delete auto created folders in e.g. "to" as for some reason files in that folder would become "unvisible" in overlayfs resulting folder, asked a question:
# https://unix.stackexchange.com/questions/679391/unionfs-deleting-folder-from-upperdir-results-in-diappearance-of-files-in-the-o
# If deleted anyway, fixing maybe by overlayfs `mount -o remount` 

# After done with modifications to make new `squashfs` file, needs to be free space there  
# putting in folder of previously created for new iso
sudo mksquashfs fin_sq fin/casper/filesystem.squashfs 

bash -i

# --- end of squashfs ---

# --- generate new iso image ---

# omitting `-eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot` resulted in USB able to boot in legacy mode only
sudo genisoimage -lJr -o new.iso -V lm20_fan -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 --boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot fin
sudo isohybrid --uefi new.iso

# not can write to USB stick, was tested to boot both legacy and EFI
# may check via below, should output like "DOS/MBR boot sector; partition 2 : ID=0xef, start-CHS (0x3ff,254,63), end-CHS (0x3ff,254,63), startsector 640, 7936 sectors"
file new.iso

# now delete intermediary data

sudo umount fin_sq
sudo umount fin
sudo umount iso_sq
sudo umount iso
sudo rm -R iso to temp fin iso_sq fin_sq temp_sq to_sq

------------- THE END ---------------------

--- Notes:


-----


man losetup
--show Display the name of the assigned loop device if the -f option and a file argument are present.

-f, --find [file]
              Find the first unused loop device.  If a file argument is present, use the found device as loop device.  Otherwise, just print its name.

       -P, --partscan
              Force  the kernel to scan the partition table on a newly created loop device.  Note that the partition table parsing depends on sector sizes.  The default is sector size is 512 bytes, otherwise you need to use the option --sector-size together with
              --partscan.



---

https://unix.stackexchange.com/questions/316401/how-to-mount-a-disk-image-from-the-command-line
fdisk -lu /path/disk.img
mount -o loop,offset=xxxx /path/disk.img /mnt/disk.img.partition
The offset value is in bytes

https://superuser.com/questions/211338/how-to-mount-a-multi-partition-disk-image-in-linux
You can use kpartx or partx to create loop devices for the partitions on the image, and then mount them


Hidden HPFS/NTFS (Bootable)

enisoimage -lJr -o lm1.iso -b isolinux/isolinux.bin -c isolinux/boot.cat fin
I: -input-charset not specified, using utf-8 (detected in locale settings)
Size of boot image is 80 sectors -> genisoimage: Error - boot image 'fin/isolinux/isolinux.bin' has not an allowable size.

---

See:
https://unix.stackexchange.com/questions/675211/mkisofs-error-boot-image-efibot-img-not-an-allowable-size/679412#679412
https://unix.stackexchange.com/questions/80305/mounting-a-squashfs-filesystem-in-read-write/679365#679365

Note: question written in 2013, now is 2021, I assume `overlayfs` (one of `unionfs` filesystems) is supported. This answer is basically merge of two other answers with some things written explicitly, proficient Linux users might see something as obvious (like using `sudo`), but not everybody is at that level, I've understood some things along the way and writing complete (IMO) instructions. Texts after `#` are comments, no need to copy them, on my system `bash` safely ignores them.

    
    cd somefolder # some folder, no need for much free space, enough for modified data only
    mkdir fm # for mounting original
    mkdir to # for upper unionfs layers
    mkdir temp # some overlayfs technical folder
    mkdir fin # resulting folders/files would be there
    
    sudo mount /full_path/filesystem.squashfs fm -t squashfs -o loop
    sudo mount -t overlay -o lowerdir=fm,upperdir=to,workdir=temp overlay fin

Now can modify/add/delete files/folders in either "to" or "fin" folders.
Changes to them are "mirrored".  
To undo deletion of original file delete "deleted" file from "to" with `sudo rm path/file`.  
After done with modifications to make new `squashfs` file in full_path folder, needs to be free space there:  

    sudo mksquashfs fin /full_path/filesystem.squashfs 

When you don't need your working files anymore:  

    sudo umount fin
    sudo umount fm
    sudo rm -R fm fin temp to

P.S. After change to `quashfs` I wanted to recreate `iso` file of modern distro which support both legacy and EFI boot. Why some options to below `genisoimage` command are critical, I don't know, for me I was trial-and-error way. Boots both EFI and legacy, however start of iso is different: starts `33 ed 90` instead of `45 52 08`, e.g. mjg59.dreamwidth.org/11285.html hints me Apple support is missing.

    mkdir iso,efi
    
    sudo losetup --partscan --show --find original.iso
    
    # if output of previous loop0
    sudo mount /dev/loop0p1 iso
    sudo mount /dev/loop0p2 efi # not necessary, just to see contents
    
    sudo mount -t overlay -o lowerdir=iso,upperdir=to,workdir=temp overlay fin
    
Replace what is needed in `fin`. Initially did `sudo dd if=/dev/loop0p2 fin/EFI/BOOT/usb.efi` to make image for efi, then found out it is already present in `grub` folder. If one takes available efi image, than `losetup+mount /dev/loop` steps can be replaced by simpler `sudo mount original.iso iso` 

    sudo genisoimage -lJr -o new.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 --boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot fin
    
    sudo isohybrid --uefi new.iso
