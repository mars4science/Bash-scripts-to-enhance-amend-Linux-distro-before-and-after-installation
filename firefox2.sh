#!/bin/bash

trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# does & at the end needed?
firefox -no-remote -P name_of_profile


