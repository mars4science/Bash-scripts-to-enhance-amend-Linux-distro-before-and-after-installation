#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# change hardly visible red to yellow in git output. To see all available places to change color, type git config --global color. and tab
# list of colors in "git help config"
git config --global color.status.changed yellow
git config --global color.diff.old yellow
