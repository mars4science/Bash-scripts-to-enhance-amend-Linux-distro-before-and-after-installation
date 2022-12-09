#!/bin/bash

# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# ---- auto script  ----- #
# ---- manual way is after auto script (note: manual outdated, auto up-to-date)  ----- #

# script produced errors when run from location in path containing spaces, not all variables are fully quoted in scripts (TODO)

# ---- parameters ---- #
distro_label="LM_20.2_AM_full_v_1.4" # arbitrary string, not sure script written to process space and bash-special symbols as author envisioned

software_path_root=/media/$(id --user --name)/usb/LM_20.2 # the script is written to look for software to take from there
original_iso="${software_path_root}"/linuxmint-20.2-cinnamon-64bit.iso # the script is written to look there for original ISO

work_path=/media/zramdisk # the script is written to create temporary files and resulting ISO there (free space "expected")

# put standard liveUSB system user name, "mint" for Linux Mint (used in run_at_boot_liveusb.sh - custom init script)
user_name=mint

# as after_original_distro_install.sh to be run in chrooted environment there is code to map (via mount) software_path_root to  path_to_software_in_chroot - where above mentioned script is written to look for software
path_to_software_in_chroot="/software_to_add"
liveiso_path_scripts_in_chroot=/usr/bin/am-scripts
liveiso_path_settings_in_chroot=/usr/share/am-settings
# ---- parameters end ---- #

if [ ! -e "$original_iso" ]; then delay=5; echo original iso file not found at $original_iso, ending script in $delay seconds; sleep $delay; exit 1; fi

script_path="$(dirname "$(realpath "$0")")"

# write commands what do amend in resulting live system
change_squash() {

    # remove need to press ENTER at shutdown
    sudo perl -i -pe 's/prompt=1/prompt=/' $work_path/fin_sq/usr/sbin/casper-stop

    # copy user specific scripts to be run later (later some [maybe all expect dconf_config as maybe it requires systemd running] expected to be moved to initrd change in change_boot() function)

    scripts_to_copy_to=$work_path/fin_sq/$liveiso_path_scripts_in_chroot
    settings_to_copy_to=$work_path/fin_sq/$liveiso_path_settings_in_chroot

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
    sudo sed --in-place --regexp-extended -- "s|liveiso_path_scripts_root|$liveiso_path_scripts_in_chroot|" $scripts_to_copy_to/systemd_to_run_as_user.sh
    sudo sed --in-place --regexp-extended -- "s/user_name=mint/user_name=$user_name/" $scripts_to_copy_to/run_at_boot_liveusb.sh

    sudo sed --in-place --regexp-extended -- "s|liveiso_path_settings_root|$liveiso_path_settings_in_chroot|" $scripts_to_copy_to/transmission_setup.sh
    sudo sed --in-place --regexp-extended -- "s|liveiso_path_settings_root|$liveiso_path_settings_in_chroot|" $scripts_to_copy_to/xscreensaver_setup.sh
    sudo cp --recursive "${software_path_root}"/settings $settings_to_copy_to

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

    sudo chroot $work_path/fin_sq /bin/bash -c "software_path_root=${path_to_software_in_chroot}; export software_path_root; liveiso_path_scripts_root=${liveiso_path_scripts_in_chroot}; export liveiso_path_scripts_root; /media/root/Scripts/after_original_distro_install.sh"
    if [ $? -ne 0 ]; then echo "=== That code has been written to display in case of non zero exit code of chroot of after_original_distro_install.sh ==="; fi
}

# write commands what do amend in boot environment
change_boot() {
    # modify boot config
    # [2]
    # ======= for UEFI boot =======
    # 	linux	/casper/vmlinuz  file=/cdrom/preseed/linuxmint.seed boot=casper iso-scan/filename=${iso_path} toram --
    # duplicate first menu entry three times, \s\S needed as in perl . (dot) does not include end of line
    perl -0777e 'while(<>){s/(menuentry[\s\S]*?\n\}\n)/\1\1\1\1/;print "$_"}' $work_path/fin/boot/grub/grub.cfg | 1>/dev/null sudo tee $work_path/fin/boot/grub/grub.cfg_tmp
    sudo mv --force $work_path/fin/boot/grub/grub.cfg_tmp $work_path/fin/boot/grub/grub.cfg
    # change first manu entry to boot to ram, add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| toram init=$liveiso_path_scripts_in_chroot/run_at_boot_liveusb.sh --|" $work_path/fin/boot/grub/grub.cfg
    sudo sed --in-place --regexp-extended -- '0,/64-bit"/s//64-bit to RAM, verbose (UEFI: all menu entries)"/' $work_path/fin/boot/grub/grub.cfg
    # change second manu entry to make text mode boot, add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| level 3 init=$liveiso_path_scripts_in_chroot/run_at_boot_liveusb.sh --|" $work_path/fin/boot/grub/grub.cfg
    sudo sed --in-place --regexp-extended -- '0,/64-bit"/s//64-bit, text mode, verbose"/' $work_path/fin/boot/grub/grub.cfg
    # change third manu entry to add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| init=$liveiso_path_scripts_in_chroot/run_at_boot_liveusb.sh --|" $work_path/fin/boot/grub/grub.cfg
    sudo sed --in-place --regexp-extended -- '0,/64-bit"/s//64-bit, verbose"/' $work_path/fin/boot/grub/grub.cfg
    # change forth menu entry to add custom init script, 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| quiet splash init=$liveiso_path_scripts_in_chroot/run_at_boot_liveusb.sh --|" $work_path/fin/boot/grub/grub.cfg
    sudo sed --in-place --regexp-extended -- '0,/64-bit"/s//64-bit, quiet"/' $work_path/fin/boot/grub/grub.cfg
    # add timeout to start first meny entry automatically (for some reason default script cfg does not have it)
    echo | sudo tee --append $work_path/fin/boot/grub/grub.cfg > /dev/null
    echo "set timeout_style=menu" | sudo tee --append $work_path/fin/boot/grub/grub.cfg > /dev/null
#    echo 'if [ "${timeout}" = 0 ]; then' | sudo tee --append $work_path/fin/boot/grub/grub.cfg > /dev/null
    echo "set timeout=5" | sudo tee --append $work_path/fin/boot/grub/grub.cfg > /dev/null
#    echo "fi" | sudo tee --append $work_path/fin/boot/grub/grub.cfg > /dev/null

    # ======= for legacy boot =======
    #   append  file=/cdrom/preseed/linuxmint.seed boot=casper initrd=/casper/initrd.lz toram --
    # edit menu title
    sudo sed --in-place -- 's/\(menu title\).*/\1 Linux Mint 20.2 64-bit based (legacy boot)/' $work_path/fin/isolinux/isolinux.cfg
    # duplicate first menu entry two times, \s\S needed as in perl . does not include end of line   
    perl -0777e 'while(<>){s/(label[\s\S]*?--\n)(menu default\n)/\1\2\1\1\1/;print "$_"}' $work_path/fin/isolinux/isolinux.cfg | 1>/dev/null sudo tee $work_path/fin/isolinux/isolinux.cfg_tmp    
    sudo mv --force $work_path/fin/isolinux/isolinux.cfg_tmp $work_path/fin/isolinux/isolinux.cfg
    # edit in-place, add three more rows number of rows in the menu
    sudo perl -i -pe 's/(MENU ROWS )([0-9]+)/$1.($2+3)/e' $work_path/fin/isolinux/isolinux.cfg
    sudo perl -i -pe 's/(TABMSGROW )([0-9]+)/$1.($2+3)/e' $work_path/fin/isolinux/isolinux.cfg
    sudo perl -i -pe 's/(CMDLINEROW )([0-9]+)/$1.($2+3)/e' $work_path/fin/isolinux/isolinux.cfg

    # change first manu entry to boot to ram, add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- '0,/label.*/s//label ram/' $work_path/fin/isolinux/isolinux.cfg
    sudo sed --in-place --regexp-extended -- '0,/( *menu label.*Mint)$/s//\1 (to RAM, verbose)/' $work_path/fin/isolinux/isolinux.cfg
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| toram init=$liveiso_path_scripts_in_chroot/run_at_boot_liveusb.sh --|" $work_path/fin/isolinux/isolinux.cfg
    # change second manu entry to add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- '0,/label.*/s//label text/' $work_path/fin/isolinux/isolinux.cfg
    sudo sed --in-place --regexp-extended -- '0,/( *menu label.*Mint)$/s//\1 (text mode, verbose)/' $work_path/fin/isolinux/isolinux.cfg
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| level 3 init=$liveiso_path_scripts_in_chroot/run_at_boot_liveusb.sh --|" $work_path/fin/isolinux/isolinux.cfg
    # change third manu entry to add custom init script, make verbose; 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- '0,/label.*/s//label verbose/' $work_path/fin/isolinux/isolinux.cfg
    sudo sed --in-place --regexp-extended -- '0,/( *menu label.*Mint)$/s//\1 (verbose)/' $work_path/fin/isolinux/isolinux.cfg
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| init=$liveiso_path_scripts_in_chroot/run_at_boot_liveusb.sh --|" $work_path/fin/isolinux/isolinux.cfg
    # change forth menu entry to add custom init script, 0,/ needed to edit first occurence only
    sudo sed --in-place --regexp-extended -- "0,/ quiet splash --/s|| quiet splash init=$liveiso_path_scripts_in_chroot/run_at_boot_liveusb.sh --|" $work_path/fin/isolinux/isolinux.cfg
    sudo sed --in-place --regexp-extended -- '0,/( *menu label.*Mint)$/s//\1 (quiet)/' $work_path/fin/isolinux/isolinux.cfg
    # edit timeout
    sudo sed --in-place -- 's/\(timeout\).*/\1 50/' $work_path/fin/isolinux/isolinux.cfg

    # code to repalce memtest to start with stock iso
    sudo cp "${software_path_root}/memtest86+/memtest86+-5.31b.bin" $work_path/fin/casper/memtest


# TODO add changing initramfs / initrd 

    # change initrd (e.g. change live session user id - DONE)
#    sudo unmkinitramfs $work_path/fin/casper/initrd.lz $work_path/initrd


# Clear out debconf database again to avoid confusing ubiquity later.

}

u_mount(){
    # proc path exists before script, mount_path is relative, so grep, not just `findmnt "$mount_path"` and current folder is "expected" to be $work_path
    # no need to escape " inside command substitution as double quotes preserve literal meaning of qouble quotes (man bash: search for "QUOTING")
    if [ -n "$(findmnt | grep "$1" | head -n 1)" ]; then sudo umount "$1"; fi
}

un_mount_in_squashfs(){
    u_mount fin_sq/dev/pts
    u_mount fin_sq/dev
    u_mount fin_sq/proc
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
        delay=0
        if [ $Eval -ne 0 ]; then
            echo "Deleting contents unsuccessful (per return code);this script is written to end in $delay seconds"; sleep $delay; exit 1;
        fi
        echo "Deleting contents successful (per return code); this script is written to continue in $delay second(s)"; sleep $delay;
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

change_boot

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

change_squash

if [ "$interactive_mode" = "true" ]; then
    echo "Next in addition to now hardcoded changes one can modify system in $work_path/fin for boot time and"
    echo "in $work_path/fin_sq for resulting live system."
    echo "now code to invoke bash in chrooted environment; type "\""exit"\"" to continue the srcipt and build new iso"
    sudo chroot $work_path/fin_sq
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
