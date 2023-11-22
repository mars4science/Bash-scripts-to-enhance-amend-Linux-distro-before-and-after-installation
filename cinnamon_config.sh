#!/bin/bash
# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; sleep 10; exit $err' ERR

# here change setting not particular to each user (as opposed to e.g. dconf settings, which AFAIK need to be run for each user - IIRC I have not found a way to change system-wide defaults).

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi

## edit applet settings

# 0777 to process file as one line - hence make only one replacement, -i edit file in place, -e execute script that follow it
# -p assume loop make it work like sed, see "perldoc perlrun"
sudo perl -i -p0777 -e "s/nothing/percentage_time/" /usr/share/cinnamon/applets/power@cinnamon.org/settings-schema.json

## edit panel
# [1] (but maybe running `glib-compile-schemas` at the end fixed [1])

# editing either /usr/share/glib-2.0/schemas/org.cinnamon.gschema.xml or 10_cinnamon.gschema.override is expected to work, decided to work via override file.
path_of_applets_to_activate="$software_path_root/cinnamon-applets/to_add_and_activate/"
glib_schemas_location=/usr/share/glib-2.0/schemas
schema_base_file="${glib_schemas_location}"/org.cinnamon.gschema.xml
schema_override_file="${glib_schemas_location}"/10_cinnamon.gschema.override
if [ ! -e "$schema_override_file" ]; then
    echo '[org.cinnamon]' | sudo tee "${schema_override_file}" > /dev/null
    override_already_used=1 # false
elif [ -n "$(grep "enabled-applets=" "${schema_override_file}")" ]; then # -n string: True if the length of string is non-zero.
    override_already_used=0 # true
else
    override_already_used=1 # false
fi

to_add_via_sed="s/]/"
qty_to_activate=0
for d in "${path_of_applets_to_activate}"* ; do
    applet_UUID="$(basename ${d})"
    grep --quiet -- "${applet_UUID}" "${schema_override_file}"
    if [ $? -ne 0 ]; then
        to_add_via_sed="${to_add_via_sed}"", 'panel1:right:"$qty_to_activate":""${applet_UUID}""'"
        ((qty_to_activate++))
    fi
done
to_add_via_sed="${to_add_via_sed}""]/"

if [ "${qty_to_activate}" -gt 0 ]; then
    if [ "${override_already_used}" -eq 1 ]; then # override not used

        # find needed line; remove "default." from beginning of the line; change positional numbers of applets to free room for new ones to be placed at the beginning (on the left); replacing closing bracket "]" with new applets and bracket
        changed_panel=`grep 'panel1:right:' "${schema_base_file}" | perl -pe 's/ *.{1,2}default.//g' | perl -pe 's/(right:)([0-9]+)/$1.($2+'$qty_to_activate")/eg" | sed "${to_add_via_sed}"`
    # perl -pe "${to_add_via_...}"` - changed to sed as for perl @ symbol is for variables, along with $ (Cinnamon applet UUIDs are often in the form of notation like for e-mail: a@b.c)

        echo "enabled-applets=${changed_panel}" | sudo tee --append "${schema_override_file}" > /dev/null
    else
        changed_panel=`grep 'panel1:right:' "${schema_override_file}" | perl -pe 's/(right:)([0-9]+)/$1.($2+'$qty_to_activate")/eg" | sed "${to_add_via_sed}"`
        sudo sed --in-place "s/enabled-applets=.*/${changed_panel}/" "${schema_override_file}"
    fi

    sudo glib-compile-schemas "${glib_schemas_location}"
fi

#
## edit applications in menu for better discoverability
#

# parameters: path, key, text
edit_line(){
    if [ -n "${3}" ]; then
        if [[ $(grep "^${2}=" "${1}") ]]; then # true if grep finds
            sudo sed --in-place "s|${2}=.*|${2}=${3}|" "${1}"
        else
            echo -e "\n${2}=${3}" | sudo tee --append "${1}"
        fi
    fi
}

edit_desktop_file(){
    if [ "${1}" == "${1%.desktop}" ]; then
        path_to_edit="${1}.desktop"; else path_to_edit="${1}";fi
    path_to_edit="/usr/share/applications/${path_to_edit}"
    if [ -e "${path_to_edit}" ]; then
        edit_line "${path_to_edit}" "Keywords" "${2}"
        edit_line "${path_to_edit}" "Comment" "${3}"
        edit_line "${path_to_edit}" "MimeType" "${4}"
        edit_line "${path_to_edit}" "Name" "${5}"
    fi
}
# parameters: desktop file name SHORT (sans .desktop suffix) or FULL (with .desktop suffix), [keywords], [comments], [MimeType], [Name]
# empty string meaning not change/add this position; strings not to include '|' as used as delimiter by sed
edit_desktop_file "libreoffice-calc" "Tables;Accounting;Stats;OpenDocument Spreadsheet;Chart;Calculator;Microsoft Excel;Microsoft Works;OpenOffice" # LibreOffice Calc
edit_desktop_file "virt-manager" "Emulators;Virtualization;KVM;QEMU;vmm" # Virtual Machines Manager
edit_desktop_file "kazam" "capture;screenshot;screencast;videorecord;desktop recording" # Kazam (screen capture)
edit_desktop_file "com.github.maoschanz.drawing" "image;picture;photo;paint;draw;Paint;Sketch;Pencil" # Drawing
edit_desktop_file "dwww" "documentation;information;manual;help" "Browse, search documentation files in /usr/share/doc, man pages" # Debian Documentation Browser
edit_desktop_file "io.github.Hexchat" "IM;Chat;IRC;messaging;message" "Chat with other people online; Internet Relay Chat"
edit_desktop_file "org.gnome.gedit" "" "" "application/x-shellscript;text/plain;" "Gnome Text Editor" # edit MimeType and Name for gedit


## change how dwww is executed (add check for apache status)
path_to_edit=/usr/share/applications/dwww.desktop
if [[ -e "$path_to_edit" ]]; then

    # TODO: try to understand how to use _BROWSER variables in /etc/dwww/dwww.conf
    # for now to use dwww in text mode run `dwww` in bash, to run in GUI (firefox) use Cinnamon menu

    # TODO: understand why extra escapes with \ needed for $ and also three of \, not just '\''\'\'''\''\n'\''\'\'''\'', which is double replacement of ' with '\'' for '\n'; as cgid waw started instead of cgi the below was commented out, left here for TODO
    # passing grep on command line two PATTERNS separated by a line break (man grep) via $'\n' (man bash)
#    sudo sed --in-place -- 's~^Exec=.*~Exec=bash -c '\''a2dismod cgi |\& grep "not found"\$'\''\\'\'''\''\\n'\''\\'\'''\''"already disabled"; if [ $? -eq 0 ] ; then zenity --info --width=500 --text="sudo a2enmod cgi ; sudo service apache2 restart - suggestion: successful executition of those two commands needed for dwww to work.    TL;DR Seems cgi module of apache is disabled/not found. Suggestion is to copy and run commands displayed at the end of this message (after :) in terminal to enable functionality, then start dwww from Cinnamon menu again (note: proper functioning of text browser run from terminal by command dwww also requires cgi module to be enabled): sudo a2enmod cgi ; sudo service apache2 restart" ; else firefox localhost/dwww  ; fi'\''~' "$path_to_edit"

    # TODO learn format of text for Zenity, using "sudo a2enmod cgi \\\&\\\& sudo service apache2 restart" results in
    # Gtk-WARNING **: ... :Failed to set text ... from markup due to error parsing markup: Error on line 1: Entity name “& sudo service apache2 restart - suggestion: successful executition of that beforehand is needed for documentation browser to work.    TL” is not known
    # TODO add format description to man page of zenity

    sudo sed --in-place -- 's~^Exec=.*~Exec=bash -c '\''a2enmod cgi ; if [ $? -eq 127 ] ; then zenity --info --width=500 --text="Seems apache is not running; this code is written not to try to start documentation browser in that case"; elif [ -e "/etc/apache2/mods-enabled/cgid.conf" ] || [ -e "/etc/apache2/mods-enabled/cgid.conf" ] ; then firefox localhost/dwww ; else zenity --info --width=500 --text="sudo a2enmod cgi ; sudo service apache2 restart - suggestion: successful executition of that beforehand is needed for documentation browser to work.    TL;DR Seems cgi module of apache is disabled. Suggestion is to copy and run commands displayed at the end of this message (after :) in terminal to enable functionality, then use same Cinnamon menu entry again (note: proper functioning of text-based browser run from terminal by command dwww also required cgi module to be enabled): sudo a2enmod cgi ; sudo service apache2 restart" ; fi'\''~' "$path_to_edit"

fi

# Add themes for custom keybinding to toggle dark/light
link_theme(){
    if [ ! -d "${1}/${2}" ]; then
        sudo ln --relative --symbolic "${1}/${3}" "${1}/${2}"; fi # make link ${2};
}
# Noted Mint-Y appearance changed from LM 21 to 21.2 from yellowish to greenish, so now attemping to use more "specifc" themes, on 21.2 result of 'Mint-Y-Dark-Teal' is interesting even as there seems to be no such theme available for choosing in GUI
link_theme /usr/share/themes 'A-Dark' 'Mint-Y-Dark-Blue'
link_theme /usr/share/icons 'A-Dark' 'Mint-X'
link_theme /usr/share/themes 'A-Light' 'Mint-X'
link_theme /usr/share/icons 'A-Light' 'Mint-X'

exit

# Notes:
[1]
# Adding cinnamon applets to right lower panel (to the left of all the rest - clock, wifi etc.)
# did not result in panel change for some reason
# DONE: find out the reasons to the above, see below:
# looks like result depends on speed of boot process, based on response to created github issue moved panel editing to
# editing /usr/share/glib-2.0/schemas org.cinnamon.gschema.xml or 10_cinnamon.gschema.override
# in cinnamon_config.sh
applets_orig=`dconf read /org/cinnamon/enabled-applets`
applets_changed=`echo $applets_orig | perl -pe 's/(right:)([0-9]+)/$1.($2+2)/eg' | perl -pe "s/]/, 'panel1:right:0:mem-monitor-text\@datanom.net:100', 'panel1:right:1:temperature\@fevimu:101']/"`
dconf write /org/cinnamon/enabled-applets "['']"
gsettings set org.cinnamon enabled-applets "['']"
dconf write /org/cinnamon/enabled-applets "$applets_changed"
