#!/bin/bash

# to be run after run_at_boot_config.sh

trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# man sed:
#  -E, -r, --regexp-extended
#              use extended regular expressions in the script (for portability use POSIX -E).

# update grub wait time
sudo sed --in-place --regexp-extended -- 's/GRUB_TIMEOUT=[0-9]{1,}/GRUB_TIMEOUT=3\nGRUB_RECORDFAIL_TIMEOUT=10/' /etc/default/grub
sudo sed -i -E -- 's/GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub

# add menu entry to start in text mode (level 3 of kernel?) by getting first menu enrty and adding 3 to vmlinuz line also adding "level 3" to menu entry name and "-level-3" to id
sed '/^menuentry/,/}/!d' /boot/grub/grub.cfg | sed -n '0,/}/p' | sed -E 's/(.*'\''.*)('\''.*'\''.*)('\'' )/\1 level 3\2-level-3\3/' | sed -E 's/(.*vmlinuz.*)/\1 3/' | 1>/dev/null sudo tee --append /etc/grub.d/40_custom

# sudo sed -i -E -- 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub

# Normally, 'grub-mkconfig' will generate top level menu entry for
# the kernel with highest version number and put all other found
# kernels or alternative menu entries for recovery mode in submenu.
# For entries returned by 'os-prober' first entry will be put on top
# level and all others in submenu.  If this option is set to 'y',
# flat menu with all entries on top level will be generated instead.
# echo 'GRUB_DISABLE_SUBMENU="y"' | sudo tee /etc/default/grub

sudo update-grub
# /boot/grub/grub.cfg - resulting config including menu entries
