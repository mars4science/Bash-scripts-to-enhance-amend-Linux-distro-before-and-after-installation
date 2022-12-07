#!/bin/bash
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

echo Configuring zram disk
sudo modprobe zram num_devices=2 # use `modprobe -r` to turn zram off (after umount zramdisk)
# cat /sys/block/zram0/comp_algorithm # shows algorithms
# 0.1% of disk size is used internally - think when allocating more than will be needed

zram_device=zram0 # to be used as disk
available_ram=$(free -wb | awk '/^Mem:/ { print $8 }')
echo lz4hc | sudo tee /sys/block/$zram_device/comp_algorithm # lz4hc is high compression
echo $(( $available_ram*2 )) | sudo tee /sys/block/$zram_device/disksize # disk size, 0.1% used internally - think when allocating more than will be needed
echo $available_ram  | sudo tee /sys/block/$zram_device/mem_limit # can be changed in runtime

sudo mkfs.ext4 -q -m 0 -b 4096 -L zramdisk /dev/$zram_device # -O sparse_super # removed that option, not sure it is useful here, once system did not release RAM after deleting large file, `df` showed as if deleted, `zramctl` as if not yet
sudo mount -o discard,noatime,X-mount.mkdir /dev/$zram_device /media/zramdisk # w/out discard memory is not made available after files deletions on the fs made on zram, `fstrim /mountpoint` discards memory unused blocks manually if discard option was not used for mount
sudo chmod a+rwxt /media/zramdisk

zram_device=zram1 # to be used as swap
echo lz4 | sudo tee /sys/block/$zram_device/comp_algorithm # lz4hc is high compression
echo $(python -c "print(int($available_ram*1.5))") | sudo tee /sys/block/$zram_device/disksize # disk size (when run VMs, noted compression achieving 1.3-1.4 ), bash does not support fractions, so use python
echo $available_ram  | sudo tee /sys/block/$zram_device/mem_limit # can be changed in runtime
sudo mkswap /dev/zram1
# sudo swapon /dev/zram1 # can be used to turn swap om; with entry in fstab can use `swapon --all`. As zram device is not available on early during boot, fstab entry does not result in automatic swap activation
echo 100 | sudo tee /proc/sys/vm/swappiness # 0 - do not use, use e.g. 100 for active swapping to zram, somewhere recall reading advice to use 200 on newer kernels 
# zramctl shows status of zram

