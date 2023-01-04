#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# here change setting not particular to each user (as opposed to e.g. dconf settings, which AFAIK need to be run for each user - IIRC I have not found a way to change system-wide defaults).

# edit applet settings
# 0777 to process file as one line - hence make only one replacement, -i edit file in place, -e execute script that follow it
# -p assume loop make it work like sed, see "perldoc perlrun"
sudo perl -i -p0777 -e "s/nothing/percentage_time/" /usr/share/cinnamon/applets/power@cinnamon.org/settings-schema.json

# edit panel
# editing /usr/share/glib-2.0/schemas/org.cinnamon.gschema.xml or 10_cinnamon.gschema.override
schema_override_file=/usr/share/glib-2.0/schemas/10_cinnamon.gschema.override
if [ ! -e "$schema_override_file" ]; then
    echo '[org.cinnamon]' | sudo tee "$schema_override_file" > /dev/null
fi

# [1]
changed_panel=`grep 'panel1:right:' /usr/share/glib-2.0/schemas/org.cinnamon.gschema.xml | perl -pe 's/ *.{1,2}default.//g' | perl -pe 's/(right:)([0-9]+)/$1.($2+2)/eg' | perl -pe "s/]/, 'panel1:right:0:mem-monitor-text\@datanom.net', 'panel1:right:1:temperature\@fevimu']/"`

echo "enabled-applets=$changed_panel" | sudo tee --append "$schema_override_file" > /dev/null
sudo glib-compile-schemas /usr/share/glib-2.0/schemas

# edit applications in menu

# add search keyword for LibreOffice Calc
path_to_edit=/usr/share/applications/libreoffice-calc.desktop
if [[ -e "$path_to_edit" ]]; then
    if [[ $(grep "Keywords=" "$path_to_edit") ]]; then # true if grep finds
        sudo sudo sed --in-place 's/Keywords=/Keywords=Tables;/' "$path_to_edit"
    else
        echo -e '\nKeywords=Tables;' | sudo tee --append "$path_to_edit"
    fi
fi

# add search keywords for Virtual Machines Manager
path_to_edit=/usr/share/applications/virt-manager.desktop
if [[ -e "$path_to_edit" ]]; then
    if [[ $(grep "Keywords=" "$path_to_edit") ]]; then # true if grep finds
        sudo sudo sed --in-place 's/Keywords=/Keywords=Emulators;Virtualization;KVM;QEMU;/' "$path_to_edit"
    else
        echo -e '\nKeywords=Emulators;Virtualization;KVM;QEMU;' | sudo tee --append "$path_to_edit"
    fi
fi

# add search keywords for Kazam (screen capture)
path_to_edit=/usr/share/applications/kazam.desktop
if [[ -e "$path_to_edit" ]]; then
    if [[ $(grep "Keywords=" "$path_to_edit") ]]; then # true if grep finds
        sudo sudo sed --in-place 's/Keywords=/Keywords=capture;/' "$path_to_edit"
    else
        echo -e '\nKeywords=capture;record;video;screen;' | sudo tee --append "$path_to_edit"
    fi
fi

exit


[1]
# Adding cinnamon applets to right lower panel (to the left of all the rest - clock, wifi etc.)
# did not result in panel change for some reason
# DONE: find out the reasons to the above, see below:
# looks like result depends on speed of boot process, based on response to created github issue moved panel editing to
# editing /usr/share/glib-2.0/schemas org.cinnamon.gschema.xml or 10_cinnamon.gschema.override
# in cinnamon_config.sh
applets_orig=`dconf read /org/cinnamon/enabled-applets`
applets_changed=`echo $applets_orig | perl -pe 's/(right:)([0-9]+)/$1.($2+2)/eg' | perl -pe "s/]/, 'panel1:right:0:mem-monitor-text\@datanom.net:100', 'panel1:right:1:temperature\@fevimu:101']/"`
dconf write /org/cinnamon/enabled-applets "['']"
gsettings set org.cinnamon enabled-applets "['']"
dconf write /org/cinnamon/enabled-applets "$applets_changed"
