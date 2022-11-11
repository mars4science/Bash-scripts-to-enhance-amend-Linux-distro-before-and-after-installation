#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

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

changed_panel=`grep 'panel1:right:' /usr/share/glib-2.0/schemas/org.cinnamon.gschema.xml | perl -pe 's/ *.{1,2}default.//g' | perl -pe 's/(right:)([0-9]+)/$1.($2+2)/eg' | perl -pe "s/]/, 'panel1:right:0:mem-monitor-text\@datanom.net', 'panel1:right:1:temperature\@fevimu']/"`

echo "enabled-applets=$changed_panel" | sudo tee --append "$schema_override_file" > /dev/null
sudo glib-compile-schemas /usr/share/glib-2.0/schemas

# edit applications in menu
sudo sudo sed --in-place 's/Keywords=/Keywords=Tables;/' /usr/share/applications/libreoffice-calc.desktop # add search keyword for LibreOffice Calc

