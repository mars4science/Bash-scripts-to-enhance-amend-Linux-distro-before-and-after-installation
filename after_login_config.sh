#!/bin/bash

trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# ~/.bashrc contains lines that overwrite PS1 from /etc/bash.bashrc, so editing ~/.bashrc to change user prompt is needed 
# if current user is root (e.g. chrooted duriong liveUSB creation), then ~ would exist, but not /home/$(id -u -n)
if [ -e /home/$(id -u -n)/.bashrc ]; then
    echo '' >> ~/.bashrc
    echo '# bash prompt, LM original and setting it' >> ~/.bashrc
    echo '# \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$' >> ~/.bashrc
    echo 'PS1='\''\[\033[01;34m\]\w\[\033[00m\]\$ '\''' >> ~/.bashrc
fi
echo '' | sudo tee --append /etc/bash.bashrc
echo 'PS1='\''\[\033[01;34m\]\w\[\033[00m\]\$ '\''' | sudo tee --append /etc/bash.bashrc
echo '' | sudo tee --append /etc/bash.bashrc

if [ -e /home/$(id -u -n)/.profile ]; then
    echo '' >> ~/.profile
    echo '# use RAM for cache' >> /home/$(id -u -n)/.profile
    # use "" to allow $id expand in echo
    echo "mount /home/$(id -u -n)/.cache" >> /home/$(id -u -n)/.profile
    echo '' >> /home/$(id -u -n)/.profile
fi

exit

-----
!!! below moved to run_at_boot_config.sh

echo '# for tmpfs /var' >> /home/$(id -u -n)/.profile
echo 'mkdir /var/spool' >> /home/$(id -u -n)/.profile
echo 'mkdir /var/cache' >> /home/$(id -u -n)/.profile
echo 'ln -s /var_on_disk/lib /var/lib' >> /home/$(id -u -n)/.profile
echo 'ln -s /var_on_disk/spool/cron /var/spool/cron' >> /home/$(id -u -n)/.profile
echo 'ln -s /var_on_disk/cache/man /var/cache/man' >> /home/$(id -u -n)/.profile
echo 'ln -s /run/lock /var/lock' >> /home/$(id -u -n)/.profile
echo 'ln -s /run /var/run' >> /home/$(id -u -n)/.profile
