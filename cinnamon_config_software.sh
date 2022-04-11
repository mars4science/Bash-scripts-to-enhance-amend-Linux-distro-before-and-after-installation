#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# edit applet settings
# 0777 to process file as one line - hence make only one replacement, -i edit file in place, -e execute script that follow it
# -p assume loop make it work like sed, see "perldoc perlrun"
sudo perl -ip0777e "s/nothing/percentage_time/" /usr/share/cinnamon/applets/power@cinnamon.org/settings-schema.json

