#!/bin/bash
# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; sleep 10; exit $err' ERR

eval "$locales" # "convert" passed argument back to array

if [ ${#locales[@]} -ne 0 ] ; then

# not sure it effects the result even if setting is made effective in other scripts (as of now this locale had not shown by `locale` back in after_original_distro_install.sh)
#    export LC_ALL=${locales[0]}.UTF-8 # LC_ALL=C.UTF-8 added to get rid of "locale: Cannot set LC_CTYPE to default locale: No such file or directory" during debs install in case locale of chrooted is different from locale of system on which scripts are run
#    echo "- Note - : 'bash: warning: setlocale: LC_ALL: cannot change locale' does not seem to prevent locales variables from being changed by previous command in the script; exact meaning of the warning: not clear"

    # some locales are added at original ISO install time, but still just in case and for liveISO - for languages (selected locales) support
    for key in "${locales[@]}"; do sudo locale-gen "$key".*; done

    # change interface language
    echo "LANG=${locales[0]}.UTF-8" | sudo tee /etc/default/locale # works, also can be done via update-locale, see below. The diffence is that tee clears whole file, update-locale need VARIABLE1= to crear each variable from the file
    echo LC_COLLATE=C.UTF-8 | sudo tee --append /etc/default/locale # added LC_COLLATE=C.UTF-8 for correct sorting of files in Nemo ( _ - before lowercase letters)
    # sudo update-locale "LANG=${locales[0]}.UTF-8" LC_ALL= LC_MESSAGES= LC_COLLATE=C.UTF-8 # works if locale for LANG is available (generated already)

    # set keyboard layouts
    # was -gt 1 (if more than 1 locale) but realized in case default language changed need to change layout just in case
    # make list with small letters of last parts separated by comma, quoted with single quotes and replace in dconf_config.sh line containing: "gsettings set org.gnome.libgnomekbd.keyboard layouts"
    layouts="gsettings set org.gnome.libgnomekbd.keyboard layouts "\""['" # need full command line in case need to be run below
    for key in "${locales[@]}"; do layouts=$layouts$(echo "$key" | awk 'BEGIN {FS = "_"}{print tolower($2)}')"', '"; done
    layouts=${layouts::-3}']"' # remove extra comma space and single quotation mark (, '), add closing bracket and double quotation mark
    if [ $running_system = "false" ]; then
        perl -i -pe 's!^.*?gsettings set org.gnome.libgnomekbd.keyboard layouts.*?(#| #|\n)!'"${layouts/$/\\$}"'$1!' "${liveiso_path_scripts_root}/dconf_config.sh" # '?' for lazy matching, '/$/\\$' to escape possible '$' - make literal symbol
    else
        # as running "${layouts}" results in "command not found", using alias
        alias gsettings_layouts="${layouts}"
        gsettings_layouts
    fi
fi

