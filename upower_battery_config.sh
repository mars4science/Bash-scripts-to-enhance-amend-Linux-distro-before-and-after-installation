#!/bin/bash
# thinkpad specific
trap 'err=$?; echo >&2 "Exiting on error $err"; exit $err' ERR

# https://askubuntu.com/questions/92794/how-to-change-critically-low-battery-value

conf_file=/etc/UPower/UPower.conf
# I have not noticed any actions on Low and Critical, Action works but only when percentage is set to lower than Low and Critical, as
# > If any value is invalid, or not in descending order, the defaults
# > will be used.
sudo sed -E --in-place=bak 's/^UsePercentageForPolicy=false/UsePercentageForPolicy=true/' $conf_file
sudo sed -E --in-place=bak 's/^PercentageLow=[0-9]{1,}/PercentageLow=30/' $conf_file
sudo sed -E --in-place=bak 's/^PercentageCritical=[0-9]{1,}/PercentageCritical=20/' $conf_file
sudo sed -E --in-place=bak 's/^PercentageAction=[0-9]{1,}/PercentageAction=10/' $conf_file
