#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

sudo -i --user=mint bash <<-EOF
    exec dbus-run-session -- bash liveiso_path_scripts_root/user_specific.sh
EOF

# for root too change theme for xed to Cobalt (for dark Cinnamon theme), some other settings just in case
sudo -i --user=root bash <<-EOF
    exec dbus-run-session -- bash liveiso_path_scripts_root/dconf_config.sh
EOF

exit

# Comments
dbus-run-session is needed as script expected to contain commands to write to dconf database
here-document (man bash) maybe for better formatting

https://unix.stackexchange.com/questions/687514/how-to-change-dconf-settings-in-chrooted-mode-via-terminal
https://askubuntu.com/questions/655238/as-root-i-can-use-su-to-make-dconf-changes-for-another-user-how-do-i-actually/1302886

