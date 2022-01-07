#!/bin/bash

# for install and update arguments
source common_arguments_to_scripts.sh

default_local_software_path=/usr/local/etc
if [ ! -d $default_local_software_path ]; then sudo mkdir --parents $default_local_software_path; fi
printf "%s" $default_local_software_path

