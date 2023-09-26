#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# change hardly visible red to yellow in git output. To see all available places to change color, type git config --global color. and tab
# for list of colors and ways to use them see "git help config"
# for list of options to set use "git help --config"
git config --global color.status.changed yellow
git config --global color.diff.old yellow
git config --global color.interactive.error "red white" # "foreground background"
git config --global color.push.error "red white"
git config --global color.remote.error "red white"

