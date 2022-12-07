#!/bin/bash

user_name=mint
usermod --uid 1000 $user_name
groupmod --gid 1000 $user_name

full_path=`realpath $0` # man realpath : Print the resolved absolute file name;
dir_name=$(dirname $full_path)
$dir_name/libvirt_access_rights.sh "$user_name"

echo custom init finish, next call /sbin/init
sleep 5
exec /sbin/init

