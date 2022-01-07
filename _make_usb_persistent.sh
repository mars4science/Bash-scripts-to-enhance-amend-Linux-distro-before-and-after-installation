#!/bin/bash

# --perl-regexp is needed to search for hex like "\xe3"

# edit one by one

# safety if run by clicking
echo to be copied from to CLI
sleep 10
exit

device_to_edit=/dev/sdb; string_to_edit="quiet splas\x68"; new_string="persistent  "; block_size=512; ed_count=0; to_end=""; if [ ! ${#string_to_edit} -eq ${#new_string} ]; then echo -e "\n Suspect a danger as strings lengths not same"; elif [ $block_size -lt ${#new_string} ]; then echo -e "\n\ Suspect a danger as block size too small for string length"; elif file_size=$(lsblk -b --output PATH,SIZE | grep "$device_to_edit " | sed -E 's/.* ([0-9]{1,})/\1/'); [ $((file_size/1024/1024/1024)) -gt 20 ]; then echo -e "\n Suspect a danger as device size is large"; else while [ -z $to_end ]; do offset_to_edit=$(sudo grep --only-matching --byte-offset --max-count=1 --text --perl-regexp "$string_to_edit" $device_to_edit | awk --field-separator ":" '{ FS = "0" ; print $1 ; exit }'); if [ -z "$offset_to_edit" ]; then echo -e "\n end of file is reached" ; to_end="yes" ; else block_to_edit=$(($offset_to_edit/$block_size)) ; sudo dd if=/$device_to_edit count=2 skip=$block_to_edit bs=$block_size | sed "s/$string_to_edit/$new_string/" | sudo dd conv=notrunc of=$device_to_edit count=2 seek=$block_to_edit bs=$block_size; echo "blocks $block_to_edit and next edited (blocks start with 0)"; ((ed_count++)) ; fi ; done ; echo -e "\n$ed_count editions made"; fi

# scan and edit all at once

date; device_to_edit=/dev/sdb; string_to_edit="quiet splash"; new_string="persistent  "; block_size=512; ed_count=0; to_end=""; if [ ! ${#string_to_edit} -eq ${#new_string} ]; then echo -e "\n Suspect a danger as strings lengths not same"; elif [ $block_size -lt ${#new_string} ]; then echo -e "\n\ Suspect a danger as block size too small for string length"; elif file_size=$(lsblk -b --output PATH,SIZE | grep "$device_to_edit " | sed -E 's/.* ([0-9]{1,})/\1/'); [ $((file_size/1024/1024/1024)) -gt 20 ]; then echo -e "\n Suspect a danger as device size is large"; else sudo grep --only-matching --byte-offset --text --perl-regexp "$string_to_edit" $device_to_edit | awk --field-separator ":" '{ FS = ":" ; print $1 }' | { IFS=$'\n' read -d '' -a offsets_to_edit ; for offset in ${offsets_to_edit[@]}; do block_to_edit=$(($offset/$block_size)) ; sudo dd if=/$device_to_edit count=2 skip=$block_to_edit bs=$block_size | sed "s/$string_to_edit/$new_string/" | sudo dd conv=notrunc of=$device_to_edit count=2 seek=$block_to_edit bs=$block_size; echo "blocks $block_to_edit and next edited (blocks start with 0)"; ((ed_count++)); done; echo -e "\n$ed_count editions made"; } ; fi; date


# edit one by one


After boot from USB extra partition writable was created w/out my intervention for overlay for persistence, if not fdisk can be used.

First variant of code is not efficient as it starts search with grep all over after each edit; but it can be stopped via ctrl-c when some changes are made.

In second variant of code grep is done only one time, but grep goes through complete file (e.g. block device, USB) which can take significant time before any editing (on my system it took ~ 15 minutes for 8Gb drive, I added date for the sake of that curiosity):

Notes:

Meaning of the scripts parameters and syntax could be understood by reading man bash, man awk, man sed, info '(coreutils) dd invocation', help read. Why (list) / { list; } needed in pipe is explained in https://stackoverflow.com/questions/2746553/read-values-into-a-shell-variable-from-a-pipe ("A pipeline may spawn a subshell, where the environment is inherited by value, not by reference"), working with two blocks is needed in case string starts in one block and ends in next one.

The scrips include three safety checks: lengths of original and replacement strings are same, block size is sufficiently large, device size is not larger then 20Gb (against accidental edit of main drive, need to be edited for larger flash storage, code is $((file_size/1024/1024/1024)) -gt 20).

There are some redundancies in the script, i.e. FS = ":" ; in awk, for some reason field separator did not work as I expected and I had to add --field-separator ":", also in grep --perl-regexp is needed to use hex e.g. \xaa values, but this edit does not have them.

# ---

Debug temp:


file_size=$(lsblk -b --output PATH,SIZE | grep "$device_to_edit " | sed -E 's/.* ([0-9]{1,})/\1/'); [ $((file_size/1024/1024/1024)) -gt 20 ];then echo -e "\n Suspect a danger as device size is large"; fi 


device_to_edit=/media/ramdrive/a; echo "aaaaaaabbbbbbbb" | sudo tee $device_to_edit; string_to_edit="b"; new_string="c"; block_size=50;

device_to_edit=/media/ramdrive/a; echo "aaaaaaabbbbbbbb" | sudo tee $device_to_edit; string_to_edit="b"; new_string="c"; block_size=50; ed_count=0; to_end=""; if [ ! ${#string_to_edit} -eq ${#new_string} ]; then echo -e "\n Suspect a danger as strings lengths not same"; elif [ $block_size -lt ${#new_string} ]; then echo -e "\n\ Suspect a danger as block size too small for string length"; elif file_size=$(lsblk -b --output PATH,SIZE | grep "$device_to_edit " | sed -E 's/.* ([0-9]{1,})/\1/'); [ $((file_size/1024/1024/1024)) -gt 20 ]; then echo -e "\n Suspect a danger as device size is large"; else while [ -z $to_end ]; do offset_to_edit=$(sudo grep --only-matching --byte-offset --max-count=1 --text --perl-regexp "$string_to_edit" $device_to_edit | awk --field-separator ":" '{ FS = "0" ; print $1 ; exit }'); if [ -z "$offset_to_edit" ]; then echo -e "\n end of file is reached" ; to_end="yes" ; else block_to_edit=$(($offset_to_edit/$block_size)) ; sudo dd if=/$device_to_edit count=2 skip=$block_to_edit bs=$block_size | sed "s/$string_to_edit/$new_string/" | sudo dd conv=notrunc of=$device_to_edit count=2 seek=$block_to_edit bs=$block_size; echo "blocks $block_to_edit and next edited (blocks start with 0)"; ((ed_count++)) ; fi ; done ; echo -e "\n$ed_count editions made"; fi


Sat 30 Oct 2021 05:51:39 AM MSK
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 0,00759631 s, 135 kB/s
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 0,00223291 s, 459 kB/s
blocks 8688 and next edited (blocks start with 0)
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 6,6676e-05 s, 15,4 MB/s
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 7,5069e-05 s, 13,6 MB/s
blocks 8689 and next edited (blocks start with 0)
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 8,1414e-05 s, 12,6 MB/s
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 0,00543395 s, 188 kB/s
blocks 8690 and next edited (blocks start with 0)
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 0,000713014 s, 1,4 MB/s
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 9,2241e-05 s, 11,1 MB/s
blocks 8692 and next edited (blocks start with 0)
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 6,4524e-05 s, 15,9 MB/s
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 0,00371869 s, 275 kB/s
blocks 8693 and next edited (blocks start with 0)
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 0,000210295 s, 4,9 MB/s
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 0,00948377 s, 108 kB/s
blocks 8693 and next edited (blocks start with 0)
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 0,000933054 s, 1,1 MB/s
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 0,0100351 s, 102 kB/s
blocks 4200113 and next edited (blocks start with 0)
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 8,5182e-05 s, 12,0 MB/s
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 0,00286649 s, 357 kB/s
blocks 4200114 and next edited (blocks start with 0)
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 9,8256e-05 s, 10,4 MB/s
2+0 records in
2+0 records out
1024 bytes (1,0 kB, 1,0 KiB) copied, 0,00683938 s, 150 kB/s
blocks 4200115 and next edited (blocks start with 0)

9 editions made
Sat 30 Oct 2021 06:04:07 AM MSK



