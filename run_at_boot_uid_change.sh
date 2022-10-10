#!/bin/bash

usermod --uid 1000 mint
groupmod --gid 1000 mint
usermod --append --groups libvirt mint
echo custom init finish, next call /sbin/init
sleep 5
exec /sbin/init

