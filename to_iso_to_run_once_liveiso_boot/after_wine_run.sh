#!/bin/bash

# make ini files be opened in GUI (Nemo) via xed again
# [1], however below is not in .wine when WINEPREFIX is empty (not set), so write as per current understanding:
sed -i --  's/x-wine-extension-ini=wine-extension-ini.desktop/x-wine-extension-ini=xed.desktop/' ~/.local/share/applications/mimeinfo.cache

# [2] during wine run output had: MESA-INTEL: warning: Performance support disabled, consider sysctl dev.i915.perf_stream_paranoid=0
sudo sysctl dev.i915.perf_stream_paranoid=0

exit

[1]
man wine
WINEPREFIX
              If set, the contents of this variable is taken as the name  of  the  directory  where  Wine
              stores  its data (the default is $HOME/.wine)

[2]
On boot, the i915 kernal module enables the paranoid performance collection mode by default. To use the VK_INTEL_performance_query extension, this paranoid mode must be disabled.
A manual approach to do this is to perform the following command:
sudo sysctl -w dev.i915.perf_stream_paranoid=0
An automated approach to do this is to add a cron job that executes whenever the platform reboots, as follows: 
sudo crontab -e # Add the following line at the end or as the 1st no comment line:
@reboot /sbin/sysctl -w dev.i915.perf_stream_paranoid=0

The "0" perf_stream_paranoid mode change can be confirmed by using the following command: 
sysctl -n dev.i915.perf_stream_paranoid

These instructions describe how to compile and use custom Linux* kernel and Mesa* Vulkan drivers that include Intel's Vulkan VK_INTEL_performance_query extension which was first published in the Khronos VulkanDocs repository as part of the 1.1.109 specification. As of January 29th, 2020, their implementation/patches are now in kernel 5.5, and the Mesa branches in 20.0 and 19.3. The VK_INTEL_performance_query extension is designed specifically for 8th generation or newer Intel GPUs including Broadwell, Skylake, Kaby Lake and Coffee Lake.

For more see https://www.intel.com/content/www/us/en/developer/articles/technical/enabling-vulkan-vk-intel-performance-query-extension-in-ubuntu.html 




