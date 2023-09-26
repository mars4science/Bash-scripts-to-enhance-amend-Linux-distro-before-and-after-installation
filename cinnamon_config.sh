#!/bin/bash
# trap 'err=$?; echo >&2 "Exiting on error $err"; sleep 10; exit $err' ERR

# here change setting not particular to each user (as opposed to e.g. dconf settings, which AFAIK need to be run for each user - IIRC I have not found a way to change system-wide defaults).

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi

## edit applet settings

# 0777 to process file as one line - hence make only one replacement, -i edit file in place, -e execute script that follow it
# -p assume loop make it work like sed, see "perldoc perlrun"
sudo perl -i -p0777 -e "s/nothing/percentage_time/" /usr/share/cinnamon/applets/power@cinnamon.org/settings-schema.json

## edit panel

# editing either /usr/share/glib-2.0/schemas/org.cinnamon.gschema.xml or 10_cinnamon.gschema.override is expected to work, decided to work via override file.
path_of_applets_to_activate="$software_path_root/cinnamon-applets/to_add_and_activate/"
glib_schemas_location=/usr/share/glib-2.0/schemas
schema_override_file="${glib_schemas_location}"/10_cinnamon.gschema.override
if [ ! -e "$schema_override_file" ]; then
    echo '[org.cinnamon]' | sudo tee "$schema_override_file" > /dev/null
fi

to_add_via_sed="s/]/"
qty_to_activate=0
for d in "${path_of_applets_to_activate}"* ; do
    applet_UUID="$(basename ${d})"
    to_add_via_sed="${to_add_via_sed}"", 'panel1:right:"$qty_to_activate":""${applet_UUID}""'"
    ((qty_to_activate++))
done
to_add_via_sed="${to_add_via_sed}""]/"

if [ $qty_to_activate -gt 0 ]; then
    # [1]
    changed_panel=`grep 'panel1:right:' /usr/share/glib-2.0/schemas/org.cinnamon.gschema.xml | perl -pe 's/ *.{1,2}default.//g' | perl -pe 's/(right:)([0-9]+)/$1.($2+'$qty_to_activate")/eg" | sed "${to_add_via_sed}"`
# perl -pe "${to_add_via_...}"` - changed to sed as for perl @ symbol is for variables, along with $ (Cinnamon applet UUIDs are often in the form of notation like for e-mail: a@b.c)

    echo "enabled-applets=${changed_panel}" | sudo tee --append "${schema_override_file}" > /dev/null
    sudo glib-compile-schemas "${glib_schemas_location}"
fi

## edit applications in menu for better discoverability

# add search keyword for LibreOffice Calc
path_to_edit=/usr/share/applications/libreoffice-calc.desktop
if [[ -e "$path_to_edit" ]]; then
    if [[ $(grep "Keywords=" "$path_to_edit") ]]; then # true if grep finds
        sudo sed --in-place 's/Keywords=/Keywords=Tables;/' "$path_to_edit"
    else
        echo -e '\nKeywords=Tables;' | sudo tee --append "$path_to_edit"
    fi
fi

# add search keywords for Virtual Machines Manager
path_to_edit=/usr/share/applications/virt-manager.desktop
if [[ -e "$path_to_edit" ]]; then
    if [[ $(grep "Keywords=" "$path_to_edit") ]]; then # true if grep finds
        sudo sed --in-place 's/Keywords=/Keywords=Emulators;Virtualization;KVM;QEMU;/' "$path_to_edit"
    else
        echo -e '\nKeywords=Emulators;Virtualization;KVM;QEMU;' | sudo tee --append "$path_to_edit"
    fi
fi

# add search keywords for Kazam (screen capture)
path_to_edit=/usr/share/applications/kazam.desktop
if [[ -e "$path_to_edit" ]]; then
    if [[ $(grep "Keywords=" "$path_to_edit") ]]; then # true if grep finds
        sudo sed --in-place 's/Keywords=/Keywords=capture;/' "$path_to_edit"
    else
        echo -e '\nKeywords=capture;record;video;screen;' | sudo tee --append "$path_to_edit"
    fi
fi

# add search keywords for Drawing
path_to_edit=/usr/share/applications/com.github.maoschanz.drawing.desktop
if [[ -e "$path_to_edit" ]]; then
    if [[ $(grep "Keywords=" "$path_to_edit") ]]; then # true if grep finds
        sudo sed --in-place 's/Keywords=/Keywords=image;picture;photo;paint;draw;/' "$path_to_edit"
    else
        echo -e '\nKeywords=image;picture;photo;' | sudo tee --append "$path_to_edit"
    fi
fi

## change how dwww is executed (add check for apache status)

# add search keywords, comment and browser for Debian Documentation Browser
path_to_edit=/usr/share/applications/dwww.desktop
if [[ -e "$path_to_edit" ]]; then
    if [[ $(grep "Keywords=" "$path_to_edit") ]]; then # true if grep finds
        sudo sed --in-place 's/Keywords=/Keywords=help;/' "$path_to_edit"
    else
        echo -e '\nKeywords=documentation;information;manual;help;' | sudo tee --append "$path_to_edit"
    fi

    if [[ $(grep "^Comment" "$path_to_edit") ]]; then # true if grep finds
        sudo sed --in-place 's|Comment=.*|Comment=Browse, search documentation files in /usr/share/doc, man pages;|' "$path_to_edit"
    else
        echo -e '\nComment=Browse, search documentation files in /usr/share/doc, man pages' | sudo tee --append "$path_to_edit"
    fi

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
