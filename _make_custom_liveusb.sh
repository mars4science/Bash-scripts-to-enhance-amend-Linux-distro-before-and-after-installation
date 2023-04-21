#!/bin/bash

# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# ---- auto script  ----- #
# ---- manual way is after auto script (note: manual outdated, auto up-to-date)  ----- #

# script produced errors when run from location in path containing spaces, not all variables are fully quoted in scripts (TODO)

# ---- parameters ---- #
distro_label="GNU-Linux_1.2-1_b21" # arbitrary string, not sure script written to process space and bash-special symbols as author envisioned

software_path_root=/media/ramdisk/LM # the script is written to look for software to take from there
original_iso="${software_path_root}"/linuxmint-21-cinnamon-64bit.iso # the script is written to look there for original ISO

work_path=/media/ramdisk/work # the script is written to create temporary files and resulting ISO there (free space "expected")
change_boot_menu="true" # set to "true" to edit boot menu (which adds options e.g. boot to ram, change id of live user, add rights for virt manager usage)
new_legacy_menu_title="GNU/Linux Cinnamon OS based on LM 21 64-bit (legacy boot)"

change_initramfs="true" # set to true to change early boot envinonment, now changing of user name is programmed
user_name=somebody # in case of change_initramfs=true put arbitrary name to set for user, in case of "false" put user name as set in the distro (used in run_at_boot_liveusb.sh - custom init script and systemd_to_run_as_user.sh - run as user during boot)

# array, list separated by space; correct syntax of each entry can be found in /etc/locale.gen (languagecode_COUNTRYCODE); used to generate locales, set keyboard layouts available for switching
# first in array also used to set system interface language, set to empty () for not doing locales changes
locales=("fr_FR" "en_US" "de_DE")

# as after_original_distro_install.sh to be run in chrooted environment there is code to map (via mount) software_path_root to  path_to_software_in_chroot - where above mentioned script is written to look for software
path_to_software_in_chroot="/tmp/path_for_mount_to_add_software_to_liveiso"
liveiso_path_scripts_in_chroot=/usr/bin/amendedliveiso-scripts
liveiso_path_settings_in_chroot=/usr/share/amendedliveiso-settings
liveiso_sources_in_chroot=/usr/src/amendedliveiso # to copy all scripts to have sources on resulting ISO
work_path_in_chroot=/tmp # used by apt_get.sh

# ---- parameters end ---- #

if [ ! -e "$original_iso" ]; then delay=5; echo original iso file not found at $original_iso, ending script in $delay seconds; sleep $delay; exit 1; fi

script_path="$(dirname "$(realpath "$0")")"

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
        echo path for scripts exists, suspect possible collision. exiting...
        echo run script again and type d to delete contents within working files, then Ctrl-C when asked for interactive
        exit 1
    else
        sudo mkdir $scripts_to_copy_to
    fi
    if [ -e $settings_to_copy_to ]; then
        echo path for settings exists, suspect possible collision. exiting...
        echo run script again and type d to delete contents within working files, then Ctrl-C when asked for interactive
        exit 1
    else
        sudo mkdir $settings_to_copy_to
    fi

    sudo cp $script_path/to_iso_to_run_once_liveiso_boot/* $scripts_to_copy_to
    for f in ${scripts_to_copy_to}/*.sh ; do
        sudo sed --in-place --regexp-extended -- "s|liveiso_path_scripts_root|$liveiso_path_scripts_in_chroot|" "$f"
        sudo sed --in-place --regexp-extended -- "s|liveiso_path_settings_root|$liveiso_path_settings_in_chroot|" "$f"
        sudo sed --in-place --regexp-extended -- "s|user=mint|user=$user_name|" "$f" # systemd_to_run_as_user.sh
        sudo sed --in-place --regexp-extended -- "s/user_name=mint/user_name=$user_name/" "$f" # run_at_boot_liveusb.sh
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
    sudo mount -t devtmpfs devtmpfs $work_path/fin_sq/dev
    sudo mount -t devpts devpts $work_path/fin_sq/dev/pts
    # note which looks as made before `mount /proc` was added: # mount  ----- output: mount: failed to read mtab: No such file or directory

    locales=$(echo "${locales[@]@A}" | sed "s/"\""/'/g") # A operator of bash generate declare line with double quotes, need to replace for bash -c below
    sudo chroot $work_path/fin_sq /bin/bash -c "export software_path_root=${path_to_software_in_chroot}; export liveiso_path_scripts_root=${liveiso_path_scripts_in_chroot}; export locales="\""${locales}"\""; export liveiso_path_scripts_root=$liveiso_path_scripts_in_chroot; export work_path=${work_path_in_chroot}; /media/root/Scripts/after_original_distro_install.sh"
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
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| showmounts toram ${custom_init_boot_option}--|" ${grub_config}
    sudo sed --in-place --regexp-extended -- '0,/64-bit"/s//64-bit to RAM, verbose (UEFI: all menu entries)"/' ${grub_config}
    # change second manu entry to make text mode boot, add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| showmounts nopersistent level 3 ${custom_init_boot_option}--|" ${grub_config}
    sudo sed --in-place --regexp-extended -- '0,/64-bit"/s//64-bit, text mode, verbose"/' ${grub_config}
    # change third manu entry to add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| showmounts nopersistent ${custom_init_boot_option}--|" ${grub_config}
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
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| showmounts toram ${custom_init_boot_option}--|" ${legacy_config}
    # change second manu entry to add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- '0,/label.*/s//label text/' ${legacy_config}
    sudo sed --in-place --regexp-extended -- '0,/( *menu label.*Mint)$/s//\1 (text mode, verbose)/' ${legacy_config}
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| showmounts nopersistent level 3 ${custom_init_boot_option}--|" ${legacy_config}
    # change third manu entry to add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- '0,/label.*/s//label verbose/' ${legacy_config}
    sudo sed --in-place --regexp-extended -- '0,/( *menu label.*Mint)$/s//\1 (verbose)/' ${legacy_config}
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| showmounts nopersistent ${custom_init_boot_option}--|" ${legacy_config}
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
    if [ -n "$(findmnt | grep "$1" | head -n 1)" ]; then sudo umount "$1"; fi
}

un_mount_in_squashfs(){
    u_mount fin_sq/dev/pts
    u_mount fin_sq/dev
    u_mount fin_sq/proc
    u_mount fin_sq/sys
    u_mount fin_sq/media/ramdisk
    u_mount fin_sq"${path_to_software_in_chroot}"
    u_mount fin_sq/media/root/Scripts
}

un_mount_in_work_path(){
    u_mount fin_sq
    u_mount fin
    u_mount iso_sq
    u_mount iso
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
            delay=10; echo "Deleting contents unsuccessful (per return code);this script is written to end in $delay seconds"; sleep $delay; exit 1;
        fi
            delay=1; echo "Deleting contents successful (per return code); this script is written to continue in $delay second(s)"; sleep $delay;
    fi    
else
    mkdir --parents $work_path && cd $_
fi

read -p "Choose interactive mode (press i key) to pause at some points, otherwise run unattended (any other key):" -n 1 -r
echo  # (optional) move to a new line
if [[ $REPLY =~ ^[Ii]$ ]]; then interactive_mode="true"; else interactive_mode="false"; fi

mkdir iso to temp fin initrd

# man mount: The mount command automatically creates a loop device from a regular file if a  filesystem  type  is
#            not specified or the filesystem is known for libblkid
# if original_iso is located on read-write mount, then mount command is expected to output a WARNING about device being write-protected; if read-only - no output expected.
# makes sense : if ro, then probably user knows about write-protection already.
sudo mount $original_iso iso #  -o loop

# maybe graft parameter of genisoimage can be used instead of overlayfs to amend mounted original iso contents
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

# After done with modifications making new `squashfs` file, needs to be free space there  
# putting in folder of previously created for new iso
un_mount_in_squashfs # if not unmounted adds e.g. /proc, which I think it not how liveUSB is made to work and it would make it less properly working   
sudo mksquashfs fin_sq fin/casper/filesystem.squashfs -noappend -b 32768 -comp zstd -Xcompression-level 22 # -comp xz
# --- end of squashfs ---

# --- generate new iso image ---
if [ $(( $(free -wm | awk '/^Mem:/ { print $8 }') - $(stat --printf="%s" fin/casper/filesystem.squashfs)/1048576 )) -le 500 ]; then
    echo "Available memory is less than 500 MB larger that squashfs file, might need more memory to complete iso file creation"
# TODO if [ "$interactive_mode" = "true" ]; then
    echo "Press (y/Y) to delete working files in $work_path/fin_sq that made up filesystem.squashfs"
    read -p "Any other key to open sub-shell to pause and add more free memory manually"  -n 1 -r
    echo  # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        un_mount_in_squashfs
        sudo rm -R fin_sq/*
    else
        echo "Type "\""exit"\"" then press "\""Enter"\"" to continue the script"
        bash -i
    fi
fi

if [ $(( $(free -wm | awk '/^Mem:/ { print $8 }') - $(stat --printf="%s" fin/casper/filesystem.squashfs)/1048576 )) -le 500 ]; then
    echo "After deleting file available memory is still less than 500 MB larger that squashfs file, might need more memory to complete iso file creation"
# TODO if [ "$interactive_mode" = "true" ]; then
    echo "Press (a/A) to abort srcipt after deleting all files in $work_path"
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
        echo "Deleting contents successful (per return code); this script is written to continue in $delay second(s)"; sleep $delay;
        exit
    else
        echo "Type "\""exit"\"" then press "\""Enter"\"" to continue the script"
        bash -i
    fi
fi


# added -allow-limited-size for squashfs file size > 2GB 
# omitting `-eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot` resulted in USB able to boot in legacy mode only
sudo genisoimage -allow-limited-size -lJr -o "$distro_label.iso" -V "$distro_label" -b isolinux/isolinux.bin -c isolinux/boot.cat \
-no-emul-boot -boot-load-size 4 --boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot fin
sudo isohybrid --uefi "$distro_label.iso"

# not can write to USB stick, was tested to boot both legacy and EFI
# may check via below, should output like "DOS/MBR boot sector; partition 2 : ID=0xef, start-CHS (0x3ff,254,63), end-CHS (0x3ff,254,63), startsector 640, 7936 sectors"
echo -e "\nNewly created distro hybrid iso file:"
file $"$work_path/$distro_label.iso"

echo "Next line is coded to invoke new bash instance; on exit all work files are coded to be removed, only iso file left"
bash -i

# now delete intermediary data
un_mount # was un_mount_in_work_path, I still do not understand why the result after next rm -R is same - all deleted
sudo rm -R iso to temp fin iso_sq fin_sq temp_sq to_sq initrd
echo "This line is after code to delete working files"

# to leave terminal open with interactive bash if started from GUI
# ps output list processes' paths as called (relative), so use "$0" 
ps --sort +pid -eo pid,stat,command | grep "$0" | head -1 | awk '{print $2}' | grep "s" > /dev/null # man ps : s    is a session leader
if [ $? -eq 0 ]; then bash -i; fi

exit


[1]
# testing gerenating CD (not USB) image:
# sudo genisoimage -lJr -o new_custom.iso -V LinuxMint_CD -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 --boot-info-table fin

[2]
# https://stackoverflow.com/questions/148451/how-to-use-sed-to-replace-only-the-first-occurrence-in-a-file









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
