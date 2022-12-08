#!/bin/bash

# needed to write to config as w/out connected printed AFAIK `lpoptions` have not changed configs
# /etc/cups/lpoptions for global settings (man lpoptions)
if [ ! -d ~/.cups ]; then mkdir ~/.cups ; fi
echo 'Default hp-color-LaserJet-2550-series ColorModel=Gray' > ~/.cups/lpoptions
exit

# when printer is connected, IIRC used:
lpoptions -l | grep Color # to find out choices of the option and printer name
# while connected (hp-color-LaserJet-2550-series for which output contains below option) may just:
lpoptions -o ColorModel=Gray

# https://unix.stackexchange.com/questions/18323/how-do-i-make-blackwhite-the-default
claims that one can define aliases (as I understood destination/instances) for sets of options and later make one of them the default.

lpoptions -p printer-model/bw -o ColorModel=Black
lpoptions -p printer-model/color -o ColorModel=RGB
# later
lpoptions -d printer-model/bw



