# support script to avoid saving and commiting regular but temporarily changes to scripts

# change label, original ISO file, keyboard layout languages, add bash fuctions and prepare for reduced set of debs to install (note: symbolic linking does not work on exFAT)

# place in parent location of folder with scripts, edit, check path to debs and run

# comment out NOT to change those
software_path_root="/media/ramdisk/LM"
distro_label="GNU-Linux_1.70_b21"
original_iso='${software_path_root}/GNU-Linux_1.68_b21.iso' # ' here as contains $

change_variable(){
    par="$1" # needed for using "an exclamation point (!)" to introduce "a level of indirection" (see man bash). '!$1' does not work because positional parameter is just number w/out '$' however indirection uses variable name and number is not valid variable name
    if [ "x${!par}" != "x" ] ; then sed -i 's|^'"${par}"'=.*#|'"${par}"'="'"${!par}"'" #|' "${file_to_change}";fi
}

file_to_change=./"Scripts_git-remote/_make_custom_liveusb.sh"
change_variable software_path_root
change_variable distro_label
change_variable original_iso

# not via function as an array variable, not enclosed in quotation marks
sed -i 's/^locales=("fr_FR" "en_US" "de_DE")/locales=("en_US" "fr_FR")/' "${file_to_change}"

#if [ "x${distro_label}" != "x" ] ; then sed -i 's/^distro_label=".*"/distro_label="'"${distro_label}"'"/' "${file_to_change}";fi
#if [ "x${original_iso}" != "x" ] ; then sed -i 's|^original_iso=.* #|original_iso="${software_path_root}"/'"${original_iso}"' #|' "${file_to_change}";fi
#if [ "x${software_path_root}" != "x" ] ; then sed -i 's|^software_path_root=.* #|software_path_root='"${software_path_root}"' #|' "${file_to_change}";fi
#

# ----------------------------------------------------------- #
# set up cgroup to redure CPU load if wanted
set -x
sudo cgcreate -g cpu:gr1
sudo cgset -r cpu.max="1000000 1000000" gr1
sudo cgexec -g cpu:gr1 sudo -u somebody -g somebody echo 'Example of running this line in gr1'
set +x

script_path="$(dirname "$(realpath "$0")")" # need to read $0 before folder change via `cd` later as `realpath` just substitutes "." (if script started from where located via ./script_name) with current folder

# make debs_virt folder in not there yet (if v pressed); make links to folder with all debs and rename to debs what's needed
read -p "Choose set of debs: press v key to select reduced set of debs to install, otherwise any other key:" -n 1 -r
echo  # (optional) move to a new line
if [[ $REPLY =~ ^[Vv]$ ]]; then 
    label="${label}"_virt
    if [ -e "${software_path_root}"/debs_virt ]; then
        mv "${software_path_root}"/debs "${software_path_root}"/debs_all
        mv "${software_path_root}"/debs_virt "${software_path_root}"/debs
    elif [ ! -e "${software_path_root}"/debs_all ]; then
        mv "${software_path_root}"/debs "${software_path_root}"/debs_all
        mkdir "${software_path_root}"/debs && cd $_

        # sleep added to copy alphabetical order to modification time order
        # seems unexpected that for same time files order by `ls `-1 --time` is not alphabetical  
        ls -1 ../debs_all | while read line ; do echo $line ; sleep 1 ; ln -s ../debs_all/$line $line ; done
        cat ../debs_to_exclude_for_virt.txt | while read line;do rm $line ; done
        cd "${script_path}" # change current folder back
    fi
else
    if [ -e "${software_path_root}"/debs_all ]; then
        mv "${software_path_root}"/debs "${software_path_root}"/debs_virt
        mv "${software_path_root}"/debs_all "${software_path_root}"/debs
    fi
fi


# add bash functions
file_to_change=./"Scripts_git-remote/bash_functions_and_other_config.sh"
text_to_add='# tests
add_function '\''t_est'\'' '\''
    echo test
'\''
'
grep --quiet "${text_to_add:0:20}" "${file_to_change}"
if [ $? -ne 0 ]; then
    echo "${text_to_add}" | tee --append "${file_to_change}"
fi

exit

# Notes
# Useful to change something in all scripts
find . -name '*.sh' -execdir bash -c 'sed -i '\''s|Exiting $0 on error $err|  ERROR: Exiting $0 on error $err|'\'' "$0"' "{}" \;

