# support script to avoid saving and commiting regular but temporarily changes to scripts

# change label, original ISO file, keyboard layout languages, add bash fuctions and prepare for reduced set of debs to install (note: symbolic linking does not work on exFAT)

# edit, check path to debs and run from repo's folder

# comment out NOT to change those
software_path_root="/media/data/LM"
distro_label="GNU-Linux_1.1_b21"
original_iso='${software_path_root}/linuxmint-21-cinnamon-64bit.iso' # ' here as contains $
work_path="/media/disk1/work1"
locales='("en_US" "fr_FR")' # note: string here whereas array in the file to edit
cgroup="gr1"

# ----------------------------------------------------------- #

script_path="$(dirname "$(realpath "$0")")" # need to read $0 before folder change via `cd` later as `realpath` just substitutes "." (if script started from where located via ./script_name) with current folder

change_variable(){
    par="$1" # needed for using "an exclamation point (!)" to introduce "a level of indirection" (see man bash). '!$1' does not work because positional parameter is just number w/out '$' however indirection uses variable name and number is not valid variable name
    if [ "x${!par}" != "x" ] ; then sed -i 's|^'"${par}"'=.*#|'"${par}"'="'"${!par}"'" #|' "${file_to_change}";fi
}

file_to_change="_make_custom_liveusb.sh"
change_variable software_path_root
change_variable distro_label
change_variable original_iso
change_variable work_path

# not via change_variable function as locales is an array variable and enclosing in quotation marks right part of assignment command chamges it to incorrect (for purposes of other parts of the scripts) array
perl -i -pe 's/^locales=\(.+?\)/locales='"${locales}"'/' "${file_to_change}"

# add bash functions
file_to_change="bash_functions_and_other_config.sh"
# length of 1st line to be at least number of symbols to select in variable in a following grep (otherwise part of 2nd line is matched too - amd separately as grep works with single lines)
text_to_add='# tests tests tests tests tests
add_function '\''t_est'\'' '\''
    echo test
'\''
'
grep --quiet "${text_to_add:0:20}" "${file_to_change}"
if [ $? -ne 0 ]; then
    printf "${text_to_add}" | tee --append "${file_to_change}"
fi

# set up cgroup to redure CPU load if wanted
set -x
sudo cgcreate -g cpu,cpuset:"${cgroup}"
sudo cgset -r cpu.max="1000000 1000000" "${cgroup}" # limit for whole CPU, write quota and period (valid values in the range of 1000 to 1000000) in microseconds, for  performance reasons could be better to use larger periods). Total CPU time in the system equals period multiplied by number of cores/processors
# sudo cgset -r cpuset.cpus="0-3" gr1 # not to use hyperthreading in typical 4 core Intel (list of cores obtained via `lscpu --all --extended`)
sudo cgset -r cpuset.cpus="0-1" "${cgroup}"
sudo cgexec -g cpu:"${cgroup}" sudo -u somebody -g somebody echo 'Example of running this line in gr1'
set +x

# end of script
exit


# Not run as of 2023/10/12
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


# Notes
# Useful to change something in all scripts
find . -name '*.sh' -execdir bash -c 'sed -i '\''s|Exiting $0 on error $err|  ERROR: Exiting $0 on error $err|'\'' "$0"' "{}" \;

