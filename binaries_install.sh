#!/bin/bash

# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi

# sudo cp --no-clobber "$software_path_root"/bin/the_rest/* "$(get_install_path.sh)" # expected to have exec bit set in
 "$software_path_root", not setting here
sudo rsync -a --chmod=Fa+x "$software_path_root"/bin/the_rest/* "$(get_install_path.sh)"

# copy apps in form of AppImage to disk and menu (to list of All Applications), follow symbolic links
# sudo cp --no-clobber --dereference "$software_path_root"/bin/appimages/* "$(get_install_path.sh)"
sudo rsync -a -L --chmod=Fa+x "$software_path_root"/bin/appimages/* "$(get_install_path.sh)"
sudo cp --no-clobber --dereference "$software_path_root"/bin/desktops/* /usr/share/applications
sudo cp --no-clobber --dereference "$software_path_root"/bin/icons/* /usr/share/pixmaps

# for desktop files to be independent of appimage files versions
for f in "$software_path_root"/bin/appimages/* ; do
    n="$(basename $f)" # all desktop file names as of now in the folder contain hythen (-) before version part, therefore:
    sudo ln --relative --symbolic "$(get_install_path.sh)/${n}" "$(get_install_path.sh)/${n%%-*}.appimage"
done
