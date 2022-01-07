#!/bin/bash

# install gecko
source install_wine-gecko.sh

# make ini files be opened in GUI (Nemo) via xed again
# [1], however below is not in .wine when WINEPREFIX is empty (not set), so write as per current understanding:
sed -i --  's/x-wine-extension-ini=wine-extension-ini.desktop/x-wine-extension-ini=xed.desktop/' ~/.local/share/applications/mimeinfo.cache

exit

[1]
man wine
WINEPREFIX
              If set, the contents of this variable is taken as the name  of  the  directory  where  Wine
              stores  its data (the default is $HOME/.wine)




