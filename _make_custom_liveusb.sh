#!/bin/bash

# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# ---- manual way is after auto script  ----- #

# ---- auto script  ----- #

distro_label="LM_20.2_AM_ram_memtest"
# original_iso=/media/$(id -un)/btrfs-1/all/ubuntu-20.04.3-desktop-amd64.iso
# original_iso=/media/$(id -un)/btrfs-1/all/LM20.2_fan_memtest.iso
original_iso=/media/data/Software/distros/linuxmint-20.2-cinnamon-64bit.iso
if [ ! -e $original_iso ]; then delay=5; echo original iso file not found at $original_iso, ending script in $delay seconds; sleep $delay; exit 1; fi 

work_path=/media/ramdrive/custom_iso

script_path="$(dirname "$(realpath "$0")")"

# write commands what do amend in resulting live system
change_squash() {
    if [ -e $work_path/fin_sq/1 ]; then
        sudo mv $work_path/fin_sq/1 $work_path/fin_sq/am
    else
        sudo mkdir $work_path/fin_sq/am
    fi
    sudo cp $script_path/bin/stopfan $work_path/fin_sq/usr/local/bin
    sudo chmod +xs $work_path/fin_sq/usr/local/bin/stopfan

    # see https://unix.stackexchange.com/questions/683439/mount-twice-bind-why-some-parameters-change-others-not
    sudo mount -o bind,x-mount.mkdir /media/$(id --user --name)/usb $work_path/fin_sq/media/root/usb
    sudo mount -o bind,remount,ro /media/$(id --user --name)/usb $work_path/fin_sq/media/root/usb

    # to run scripts located in the same folder where script run by chroot is located
    sudo mount -o bind,x-mount.mkdir $script_path $work_path/fin_sq/media/root/Scripts
    sudo mount -o bind,remount,ro $script_path $work_path/fin_sq/media/root/Scripts

    # for chrooted environment path should reflect chroot: media/root, not media/user_name, script developer expects id to work to give root
    # /media/root works in chrooted because of bind mounts above
#    sudo chroot $work_path/fin_sq /media/$(id --user --name)/usb/Projects/Scripts-git/after_original_distro_install.sh
    sudo chroot $work_path/fin_sq /media/root/Scripts/after_original_distro_install.sh
    if [ $? -ne 0 ]; then echo "=== That code has been written to display in case of non zero exit code of chroot of after_original_distro_install.sh ==="; fi
}

# write commands what do amend in boot environment
change_boot() {
    # modify boot config
    # [2]
    # for UEFI boot
    # 	linux	/casper/vmlinuz  file=/cdrom/preseed/linuxmint.seed boot=casper iso-scan/filename=${iso_path} toram --
    sudo sed --in-place --regexp-extended -- '0,/ quiet splash --/s// toram --/' $work_path/fin/boot/grub/grub.cfg

    # for legacy boot
    #   append  file=/cdrom/preseed/linuxmint.seed boot=casper initrd=/casper/initrd.lz toram --
    sudo sed --in-place --regexp-extended -- '0,/ quiet splash --/s// toram --/' $work_path/fin/isolinux/isolinux.cfg

    echo | sudo tee --append $work_path/fin/boot/grub/grub.cfg > /dev/null
    echo "set timeout_style=menu" | sudo tee --append $work_path/fin/boot/grub/grub.cfg > /dev/null
    echo 'if [ "${timeout}" = 0 ]; then' | sudo tee --append $work_path/fin/boot/grub/grub.cfg > /dev/null
    echo "  set timeout=5" | sudo tee --append $work_path/fin/boot/grub/grub.cfg > /dev/null
    echo "fi" | sudo tee --append $work_path/fin/boot/grub/grub.cfg > /dev/null

    # code to repalce memtest to start with stock iso 
    sudo cp "/media/$(id -un)/usb/LM_20.2/memtest86+/memtest86+-5.31b.bin" $work_path/fin/casper/memtest


# TODO add changing initramfs / initrd 

    # change initrd (e.g. change live session user id)
#    sudo unmkinitramfs $work_path/fin/casper/initrd.lz $work_path/initrd


# Clear out debconf database again to avoid confusing ubiquity later.






}

u_mount(){
    if [ -e "$mount_path" ]; then sudo umount $mount_path; fi
}

un_mount_in_squashfs(){
    # proc path exists before scipt, mount_path is relative, so grep, not just `findmnt "$mount_path"`
#     mount_path=fin_sq/proc;  if [ -n "$(findmnt | grep "\""$mount_path"\"" | head -n 1)" ]; then sudo umount $mount_path; fi
# quoting as above does not work, see my question on unix.se
    mount_path=fin_sq/proc;  if [ -n "$(findmnt | grep $mount_path | head -n 1)" ]; then sudo umount $mount_path; fi
    mount_path=fin_sq/media/ramdrive;  u_mount
    mount_path=fin_sq/media/root/usb;  u_mount
    mount_path=fin_sq/media/root/scripts;  u_mount
}

un_mount_in_work_path(){
    mount_path=fin_sq; u_mount
    mount_path=fin; u_mount
    mount_path=iso_sq; u_mount
    mount_path=iso; u_mount
}

un_mount(){
    un_mount_in_squashfs
    un_mount_in_work_path
}

# the rest is coded to work "universally" (w/out per distro modifications)

# x ("x") not needed because with "" strings are not empty, if first expression is not true, second is not evaluated IIRC
if [ -e "$work_path" ] && [ "$(ls $work_path)" != "" ]; then
    # https://stackoverflow.com/questions/1885525/how-do-i-prompt-a-user-for-confirmation-in-bash-script
    read -p "! $work_path exists and not empty, abort (n), proceed (y), try deleting contents within it (d)? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[YyDd]$ ]]; then exit; fi
    cd $work_path
    if [[ $REPLY =~ ^[Dd]$ ]]; then
        un_mount
        sudo rm -R $work_path/*
        delay=5; echo ending script in $delay seconds; sleep $delay; exit 0;
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
    echo "now code to invoke new bash; type "\""exit"\"" to continue the srcipt and build new iso"
    bash -i
fi

# After done with modifications making new `squashfs` file, needs to be free space there  
# putting in folder of previously created for new iso
un_mount_in_squashfs # if not unmounted adds e.g. /proc, which I think it not how liveUSB is made to work and it would make it less properly working   
sudo mksquashfs fin_sq fin/casper/filesystem.squashfs -noappend
# --- end of squashfs ---

# --- generate new iso image ---
if [ $(( $(free -wm | awk '/^Mem:/ { print $8 }') - $(stat --printf="%s" fin/casper/filesystem.squashfs)/1048576 )) -le 500 ]; then 
    echo "Available memory less than 500 MB larger that squashfs file, might need more memory to complete iso file creation"
# TODO if [ "$interactive_mode" = "true" ]; then
    echo "Press (y/Y) to delete working files in $work_path/fin_sq that made up filesystem.squashfs" 
    read -p "Any other key to open sub-shell to pause and add more free memory manually"  -n 1 -r
    echo  # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # unmounting tmpfs frees memory, although files in it are to be deleted by code on next line (rm)
        # but could be faster and not sure how tmpfs works in chrooted
        if [ -d fin_sq/media/ramdrive ]; then sudo umount fin_sq/media/ramdrive; fi
        sudo rm -R fin_sq/*
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
un_mount_in_work_path
sudo rm -R iso to temp fin iso_sq fin_sq temp_sq to_sq
echo "This line is after code to delete working files"

# to leave terminal open with interactive bash if started from GUI
# ps output list processes' paths as called (relative), so use "$0" 
ps --sort +pid -eo pid,stat,command | grep "$0" | head -1 | awk '{print $2}' | grep "s" > /dev/null # man ps : s    is a session leader
if [ $? -eq 0 ]; then bash -i; fi

exit


[1]


# [1] 
# testing gerenating CD (not USB) image:
# sudo genisoimage -lJr -o new_custom.iso -V LinuxMint_CD -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 --boot-info-table fin


# man genisoimage:
# -l     Allow  full  31-character  filenames
# -J     Generate  Joliet directory records in addition to regular ISO9660 filenames
#      -R     Generate SUSP and RR records using the Rock Ridge protocol to further describe the  files  on
#              the ISO9660 filesystem.
#       -r     This  is like the -R option, but file ownership and modes are set to more useful values.  The
#              uid and gid are set to zero, because they are usually only useful on the author's system, and
#              not useful to the client (....goes on)
#       -no-emul-boot
#              Specifies that the boot image used to create El Torito bootable CDs is a "no  emulation"  im‐
#              age. The system will load and execute this image without performing any disk emulation.
# (.... --boot-info-table -c -b -V -o )


[2]

# https://stackoverflow.com/questions/148451/how-to-use-sed-to-replace-only-the-first-occurrence-in-a-file

The first two parameters 0 and /Apple/ are the range specifier. The s/Apple/Banana/ is what is executed within that range. So in this case "within the range of the beginning (0) up to the first instance of Apple, replace Apple with Banana. Only the first Apple will be replaced.

Background: In traditional sed the range specifier is also "begin here" and "end here" (inclusive). However the lowest "begin" is the first line (line 1), and if the "end here" is a regex, then it is only attempted to match against on the next line after "begin", so the earliest possible end is line 2. So since range is inclusive, smallest possible range is "2 lines" and smallest starting range is both lines 1 and 2 (i.e. if there's an occurrence on line 1, occurrences on line 2 will also be changed, not desired in this case). GNU sed adds its own extension of allowing specifying start as the "pseudo" line 0 so that the end of the range can be line 1, allowing it a range of "only the first line" if the regex matches the first line.

Or a simplified version (an empty RE like // means to re-use the one specified before it, so this is equivalent):

sed '0,/Apple/{s//Banana/}' input_filename

And the curly braces are optional for the s command, so this is also equivalent:

----





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

My answers here:
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
