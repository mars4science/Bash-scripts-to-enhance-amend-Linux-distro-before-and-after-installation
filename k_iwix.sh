#!/bin/bash

# TODO change hardcoded location of kiwix file to copy from

# for install and update arguments
source common_arguments_to_scripts.sh
# help
help_message="  Runs kiwix appimage with some variables set as a workaround to libGL error (see footnote 1 in the script).
  Usage: $script_name\n"
display_help "$help_message$common_help"
# ====== #

# if does not exist locally, then copy
app_name="kiwix-desktop.appimage"
link_path="$(get_software_path.sh)/$app_name"

if [ ! -e "$link_path" ]; then
    if [ ! -d $(dirname "$link_path") ]; then sudo mkdir $(dirname "$link_path"); fi
    if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM_20.2 ; fi

    # not moved to /bin/appimages as cannot be run w/out workaround below
    copyfrom_path="$software_path_root/kiwix-desktop_x86_64_2.1.0.appimage"

    if [ ! -e "$copyfrom_path" ]; then echo >&2 "kiwix path $copyfrom_path not found, exiting with error"; exit 1; fi
    sudo cp "$copyfrom_path" $(dirname "$link_path")
    sudo ln -s $(dirname "$link_path")/$(basename "$copyfrom_path") $link_path
    echo "Copied and linked $app_name to $link_path, run script again to run kiwix."
    exit 0
fi

# either of the below two variable assignments works as a workaround, [1]:
# MESA_LOADER_DRIVER_OVERRIDE=i965 "$link_path"
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 "$link_path"

exit

---
[1]
https://askubuntu.com/questions/1352158/libgl-error-failed-to-load-drivers-iris-and-swrast-in-ubuntu-20-04
https://github.com/kiwix/kiwix-desktop/issues/393
https://superuser.com/questions/1377555/slic3r-appimage-fails-to-run-with-libgl-error-unable-to-load-driver-radeonsi
https://stackoverflow.com/questions/37050536/not-allow-me-to-run-the-emulator-on-android-studio-for-lack-of-driver-in-the-ope/39458071#39458071
https://gitlab.freedesktop.org/mesa/mesa/-/issues/3477

Error output in bash terminal:
libGL error: MESA-LOADER: failed to open iris: /usr/lib/dri/iris_dri.so: cannot open shared object file: No such file or directory (search paths /usr/lib/x86_64-linux-gnu/dri:\$${ORIGIN}/dri:/usr/lib/dri)
libGL error: failed to load driver: iris
libGL error: MESA-LOADER: failed to open iris: /usr/lib/dri/iris_dri.so: cannot open shared object file: No such file or directory (search paths /usr/lib/x86_64-linux-gnu/dri:\$${ORIGIN}/dri:/usr/lib/dri)
libGL error: failed to load driver: iris
libGL error: MESA-LOADER: failed to open swrast: /usr/lib/dri/swrast_dri.so: cannot open shared object file: No such file or directory (search paths /usr/lib/x86_64-linux-gnu/dri:\$${ORIGIN}/dri:/usr/lib/dri)
libGL error: failed to load driver: swrast
WebEngineContext used before QtWebEngine::initialize() or OpenGL context creation failed.
QGLXContext: Failed to create dummy context
add widget
Failed to create OpenGL context for format QSurfaceFormat(version 2.0, options QFlags<QSurfaceFormat::FormatOption>(), depthBufferSize 24, redBufferSize -1, greenBufferSize -1, blueBufferSize -1, alphaBufferSize -1, stencilBufferSize 8, samples 0, swapBehavior QSurfaceFormat::DefaultSwapBehavior, swapInterval 1, colorSpace QSurfaceFormat::DefaultColorSpace, profile  QSurfaceFormat::NoProfile) 
Aborted (core dumped)
