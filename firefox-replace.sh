#!/bin/bash

# replaces in Linux Mint modified (at least for google search) Mozilla Firefox with downloaded from Mozilla site version
# the script's code is written to process tar or zip archives with `firefox` executable to start Firefox located in root of archive or in single top folder of the archive (usually named "firefox")

ff_installed_link=$(which firefox)
# man bash:
#       -h file
#              True if file exists and is a symbolic link.
if [ -h "$ff_installed_link" ]; then ff_link_symbolic=true; else ff_link_symbolic=false; fi
# 1 argument
#                     The expression is true if and only if the argument is not null.
# therefore when $ff_installed_link is empty, then only one argument: -h so exprsssion AFAIK evaluates to true
# added "" (below too), so now expression has two arguments: -h and a string

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
ff_archive_name="$(ls --sort=time $software_path_root | grep "^firefox-" | head --lines=1)"
ff_archive=$software_path_root/$ff_archive_name
if [ ! -f "$ff_archive" ]; then echo >&2 "Firefox archive to install from not found in $software_path_root, next is exit of the script"; exit 1; fi


ff_installed_folder=$(dirname $(realpath $ff_installed_link))

# check if found folder is dedicated for firefox or as found in LM 21 it is /usr/bin, firefox application there calls somewhere (still there is similar [to ISO where firefox in /usr/bin is a link] folder /usr/lib/firefox)
if [ $(echo $ff_installed_folder | grep --ignore-case firefox) ] ; then
    echo "  Firefox has been found in the system in $ff_installed_folder, replacing is programmed in the code that follows"
    ff_toinstall_folder=$ff_installed_folder
    cd $ff_toinstall_folder
    sudo rm --recursive ./* # to replace contents of previous firefox folder
else
    ff_toinstall_folder=$liveiso_path_scripts_root/firefox
    echo "  Firefox folder has not been found in the system, adding firefox to ${liveiso_path_scripts_root} is programmed in the code that follows"
    sudo mkdir $ff_toinstall_folder # previous firefox folder not found, make somewhere safe from collision
    cd $_
fi

# extract
if [ $(echo "$ff_archive" | grep ".tar") ] ; then
    sudo tar --extract --warning=no-timestamp --file="$ff_archive" --atime-preserve --one-top-level="$ff_toinstall_folder"
elif [ $(echo "$ff_archive" | grep ".zip") ] ; then
    sudo unzip "$ff_archive" -d "$ff_toinstall_folder"
else
    echo "  ERROR: Neither tar nor zip archive format for browser, exiting"; exit 1
fi
echo "  ..found ${ff_archive} to add contents to ${liveiso_path_scripts_root}, at least that line of code is after exiting the script if archive is not found"

# in case archive have single top folder where all is
if [ $(ls "$ff_toinstall_folder" | wc | awk '{print $1}') -eq 1 ] ; then

    # ff_toinstall_folder="$ff_toinstall_folder/"$(ls "$ff_toinstall_folder");
    # now remove extra level instead:

    ff_folder_temp_name="temporary_name" # rename in case folder same as one of files - usually "firefox"
    mv "${ff_toinstall_folder}/$(ls "${ff_toinstall_folder}")" "${ff_toinstall_folder}/${ff_folder_temp_name}"
    mv "${ff_toinstall_folder}/${ff_folder_temp_name}"/* "${ff_toinstall_folder}"
    rmdir "${ff_toinstall_folder}/${ff_folder_temp_name}"
fi

# restore link that the srcipt code as written is supposed to break
if [ "$ff_link_symbolic" = "true" ]; then
    sudo ln --symbolic --force --no-target-directory $ff_toinstall_folder/firefox $ff_installed_link # adding --no-target-directory as sometimes ff_toinstall_folder points to existing directory and seems in that case ln defaults to creating link in a directory (BTW seems for bash "$a/b" in case of "a" being link to a directory resolves to "b" in that directory)
else
    # if firefox is found in delicated folder and `which firefox` is not a link, that hints that folder is in search path for executables (PATH) already
    if [[ ! ("$ff_toinstall_folder" = "$ff_installed_folder") ]]; then sudo ln --symbolic --force $ff_toinstall_folder/firefox $(get_install_path.sh) ; fi
fi

# disable updates (inc. reminders), checkDefaultBrowser to false etc. seems to work via policies.json
# editing distribution.ini is left here just in case - maybe for older FF versions

# about:policies#documentation for list of policies to set
# Potentially interesting, not set for now:
#   "DisableSystemAddonUpdate": true
#   "GoToIntranetSiteForSingleWordEntryInAddressBar": true
# "Preferences" allows to fix settings of preferences, by changing in about:preferences and checking for changes to ~/.mozilla/firefox/profile_name/prefs.js found out:
#   "browser.zoom.full": false - sets to zoom only text (often web pages only rearrage themselves after zooming-in, not enlarge images) - text only turned out to produce small text in large boxes (removed, let user change if needed, seems true by default)
#   "pref.general.disable_button.default_browser": false, "browser.shell.checkDefaultBrowser": true - not sure what they do, had changed after clicked to make FF default browser
ff_distribution_folder=$ff_toinstall_folder/distribution
sudo mkdir --parents $ff_distribution_folder # --parents : no error if existing, make parent directories as needed

echo '{"policies": {' \
'"DisableAppUpdate": true,' \
'"DontCheckDefaultBrowser": true,' \
'"DisableFirefoxStudies": true,' \
'"DisableTelemetry": true,' \
'"DisablePocket": true,' \
'"DisableFirefoxAccounts": true,' \
'"BackgroundAppUpdate": false,' \
'"AppAutoUpdate": false,' \
'"SanitizeOnShutdown": { "Cache": true },' \
'"OverrideFirstRunPage": "",' \
'"Preferences": {' \
'"app.shield.optoutstudies.enabled": false,' \
'"browser.crashReports.unsubmittedCheck.autoSubmit2": false,' \
'"browser.safebrowsing.malware.enabled": false,' \
'"browser.safebrowsing.phishing.enabled": false,' \
'"browser.safebrowsing.downloads.enabled": false,' \
'"browser.safebrowsing.downloads.remote.block_potentially_unwanted": false,' \
'"browser.safebrowsing.downloads.remote.block_uncommon": false,' \
'"datareporting.healthreport.uploadEnabled": false,' \
'"browser.startup.homepage": "chrome://browser/content/blanktab.html",'`# homepage as blank page` \
'"browser.newtabpage.enabled": false,'`# new tabs as blank page` \
'"browser.search.widget.inNavBar": true,'`# separate search widget/window/line` \
'"pref.general.disable_button.default_browser": false,' \
'"browser.startup.page": 3,'`# on startup to open previous windows and tabs` \
'"browser.shell.checkDefaultBrowser": true}}}' | 1>/dev/null sudo tee $ff_distribution_folder/policies.json

echo -e '[Preferences]\napp.update.enabled=false\nbrowser.shell.checkDefaultBrowser=false' | 1>/dev/null sudo tee $ff_distribution_folder/distribution.ini

# To set preferences create two files
# Note: `lockPref` instead of `pref` has been observed to lock preferences for the user, not only set defaults 
#   `defaultPref` is written to set default, not clear what is the difference from just `pref` (maybe if user resets to defaults - if this functionality exists?)
#   even with `defaultPref`, setting was still shown with `Show only modified preferences` in about:config
ff_actual_config_preferences_file="amended_mozilla.cfg"
ff_config_preferences_file="path_to_amended_actual_config_preferences_file.js" # local-settings.js
ff_preferences_folder="${ff_toinstall_folder}/defaults/pref"
sudo mkdir --parents "${ff_preferences_folder}" # just in case, had been already there

echo '// The file have been made based on SE post with non-Mozilla official linked page quoted and trial and error'$'\n'\
'// obscure could be something related to RET-13 ecoding'$'\n'\
'pref("general.config.obscure_value", 0);'$'\n'\
'// file where pref settings to be added as some settings work from current file but some do not (if the former setting in cfg takes precedence)'$'\n'\
'pref("general.config.filename", "'"${ff_actual_config_preferences_file}"'");' | 1>/dev/null sudo tee "${ff_preferences_folder}/${ff_config_preferences_file}"

echo '// First line seems to be ignored by parser'$'\n'\
'// The file have been made based on SE post with non-Mozilla official linked page quoted and trial and error'$'\n'\
'pref("browser.aboutConfig.showWarning", false);'$'\n'\
'// default colors for background and text (tried to actually try to set dark theme, at least for local files without CSS styles, but found out many sites set only either background or foreground resulting in same color if back is black and text is white - therefore decided to set as slightly different to original defaults to identify such sites)'$'\n'\
'pref("browser.display.background_color", "#FFF0FF");'$'\n'\
'pref("browser.display.foreground_color", "#800000");' \
| 1>/dev/null sudo tee "${ff_toinstall_folder}/${ff_actual_config_preferences_file}"

exit
#
# Notes:
#
To change colors in HTML one can use CSS, like:

<style>
    h1 {
        color: red;
    }
    body {
        color: blue;
        background-color: #000000;
    }
</style>

Adding that in the beginning of html file or in separate file (e.g. a.css) and adding (somewhere? at the beginning?) of html file a reference:

<link rel="stylesheet" href="a.css" /> <!-- Imports Stylesheets -->

