#!/bin/bash

if [ ! -d ~/.cups ]; then mkdir ~/.cups ; fi
echo 'Default hp-color-LaserJet-2550-series ColorModel=Gray' > ~/.cups/lpoptions
exit

# works only when printer is connected,therefore just make the file as above
# lpoptions -o ColorModel=Gray

# https://unix.stackexchange.com/questions/18323/how-do-i-make-blackwhite-the-default

You can configure CUPS defaults for your account by running the lpoptions command. Run lpoptions -l to see what options are available for your printer, and determine which one corresponds to the color/monochrome choice. For example, with this output

$ lpoptions -l | grep Color
ColorModel/Color Model: Gray Black *RGB CMY CMYK KCMY

I would set ColorModel to Black. Then run lpoptions -o NAME=VALUE to set a default option. This creates a file called ~/.cups/lpoptions that applications using CUPS will read.

lpoptions -o ColorModel=Black

Other printers may use different parameters, e.g.

lpoptions -o ColorType=Mono

You can define aliases for sets of options and make one of them the default.

lpoptions -p FS-C5100DN/bw -o ColorModel=Black
lpoptions -p FS-C5100DN/color -o ColorModel=RGB
lpoptions -d FS-C5100DN/bw



