#!/bin/bash

# set scaling of fonts in Cinnamon based on display's resolution and pixels density (and guesswork about overall monitor scaling factor as still have not found a way to read it by shell code)
# to be run separately from the rest of dconf settings as it seems `xrandr` does not output data when X had not started yet

dpm=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4/$(NF-1)}') # dots per millimeter, rounded as bash test works with integers only
# at least gave "integer expression expected" for [ 3.4 -eq 45 ]
dpi=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4/$(NF-1)*25.4}') # dots per inch, rounded
horizontal_resolution=$(xrandr | sed 's/x/ /g' | awk '/ connected/ {printf "%.0f",$4}')

# "gsettings set org.cinnamon.desktop.interface scaling-factor 2" does not seem to work in LM 21 (had been working in LM 20); GUI scaling controls worked in both
if [ $dpm -ge 6 ] && ([ ${horizontal_resolution} -le 2000 ] || [ ${horizontal_resolution} -ge 3500 ]); then
    # increase text scaling for primary fullhd and 4k displays; TL;DR:
    # 14 inch is 309mm width, hd is 1920, dpm=6.21
    # text scaling setting below is based on observation, but source code and/or documentation:
    # 1. if resolution is larger than 1920 seems whole dislay scaling is set to 2 by LM somewhere in code. TODO find where and how
    # 2. if resolution is less than 1920 seems whole dislay scaling is set to 1
    # 3. Text scaling results in half effect, e.g. scaling increase from 1.0 to 1.5 resulted in ~ 1.25 font size increase in list view in Nemo
    # 4. Decreasing scaling below 1 had not resulted in icons decrease in Nemo's list view, increasing above 1 had increased icons size
    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.7
fi

