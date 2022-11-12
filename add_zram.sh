#!/bin/bash
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

echo Configuring zram disk
sudo modprobe zram num_devices=1
# cat /sys/block/zram0/comp_algorithm # shows algorithms
echo lz4hc | sudo tee /sys/block/zram0/comp_algorithm # lz4hc is high compression
echo 16G | sudo tee /sys/block/zram0/disksize # disk size, 0.1% used internally - think when allocating more than will be needed
echo 9G  | sudo tee /sys/block/zram0/mem_limit # can be changed in runtime

sudo mkfs.ext4 -q -m 0 -b 4096 -L zramdrive /dev/zram0 # -O sparse_super # removed that option, not sure it is useful here, once system did not release RAM after deleting large file, `df` showed as if deleted, `zramctl` as if not yet
sudo mount -o discard,noatime,X-mount.mkdir /dev/zram0 /media/zramdrive # w/out discard memory is not made available after files deletions on the fs made on zram, `fstrim /mountpoint` discards memory unused blocks manually if discard option was not used for mount 
sudo chmod a+rwxt /media/zramdrive

